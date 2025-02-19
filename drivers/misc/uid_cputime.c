/* drivers/misc/uid_cputime.c
 *
 * Copyright (C) 2014 - 2015 Google, Inc.
 *
 * This software is licensed under the terms of the GNU General Public
 * License version 2, as published by the Free Software Foundation, and
 * may be copied, distributed, and modified under those terms.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 */

#include <linux/atomic.h>
#include <linux/err.h>
#include <linux/hashtable.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/list.h>
#include <linux/proc_fs.h>
#include <linux/profile.h>
#include <linux/sched.h>
#include <linux/seq_file.h>
#include <linux/slab.h>
#include <linux/uaccess.h>
#include <linux/cpufreq.h>

#define UID_HASH_BITS	10
DECLARE_HASHTABLE(hash_table, UID_HASH_BITS);

static DEFINE_MUTEX(uid_lock);
static struct proc_dir_entry *parent;

struct uid_entry {
	uid_t uid;
	cputime_t utime;
	cputime_t stime;
	cputime_t active_utime;
	cputime_t active_stime;
	unsigned long long active_power;
	unsigned long long power;
	struct hlist_node hash;
};

static struct uid_entry *find_uid_entry(uid_t uid)
{
	struct uid_entry *uid_entry;
	hash_for_each_possible(hash_table, uid_entry, hash, uid) {
		if (uid_entry->uid == uid)
			return uid_entry;
	}
	return NULL;
}

static struct uid_entry *find_or_register_uid(uid_t uid)
{
	struct uid_entry *uid_entry;

	uid_entry = find_uid_entry(uid);
	if (uid_entry)
		return uid_entry;

	uid_entry = kzalloc(sizeof(struct uid_entry), GFP_ATOMIC);
	if (!uid_entry)
		return NULL;

	uid_entry->uid = uid;

	hash_add(hash_table, &uid_entry->hash, uid);

	return uid_entry;
}

static int uid_stat_show(struct seq_file *m, void *v)
{
	struct uid_entry *uid_entry;
	struct task_struct *task, *temp;
	cputime_t utime;
	cputime_t stime;
	unsigned long bkt;

	mutex_lock(&uid_lock);

	hash_for_each(hash_table, bkt, uid_entry, hash) {
		uid_entry->active_stime = 0;
		uid_entry->active_utime = 0;
		uid_entry->active_power = 0;
	}

	read_lock(&tasklist_lock);
	do_each_thread(temp, task) {
		uid_entry = find_or_register_uid(from_kuid_munged(
			current_user_ns(), task_uid(task)));
		if (!uid_entry) {
			read_unlock(&tasklist_lock);
			mutex_unlock(&uid_lock);
			pr_err("%s: failed to find the uid_entry for uid %d\n",
				__func__, from_kuid_munged(current_user_ns(),
				task_uid(task)));
			return -ENOMEM;
		}
		/* if this task is exiting, we have already accounted for the
		 * time and power.
		 */
		if (task->cpu_power == ULLONG_MAX)
			continue;
		task_cputime_adjusted(task, &utime, &stime);
		uid_entry->active_utime += utime;
		uid_entry->active_stime += stime;
		uid_entry->active_power += task->cpu_power;
	} while_each_thread(temp, task);
	read_unlock(&tasklist_lock);

	hash_for_each(hash_table, bkt, uid_entry, hash) {
		cputime_t total_utime = uid_entry->utime +
							uid_entry->active_utime;
		cputime_t total_stime = uid_entry->stime +
							uid_entry->active_stime;
		unsigned long long total_power = uid_entry->power +
							uid_entry->active_power;
		seq_printf(m, "%d: %llu %llu %llu\n", uid_entry->uid,
			(unsigned long long)jiffies_to_msecs(
				cputime_to_jiffies(total_utime)) * USEC_PER_MSEC,
			(unsigned long long)jiffies_to_msecs(
				cputime_to_jiffies(total_stime)) * USEC_PER_MSEC,
			total_power);
	}

	mutex_unlock(&uid_lock);
	return 0;
}

static int uid_stat_open(struct inode *inode, struct file *file)
{
	return single_open(file, uid_stat_show, PDE_DATA(inode));
}

static const struct file_operations uid_stat_fops = {
	.open		= uid_stat_open,
	.read		= seq_read,
	.llseek		= seq_lseek,
	.release	= single_release,
};

static int uid_remove_open(struct inode *inode, struct file *file)
{
	return single_open(file, NULL, NULL);
}

static ssize_t uid_remove_write(struct file *file,
			const char __user *buffer, size_t count, loff_t *ppos)
{
	struct uid_entry *uid_entry;
	struct hlist_node *tmp;
	char uids[128];
	char *start_uid, *end_uid = NULL;
	long int start = 0, end = 0;
uid_t uid_start, uid_end;

	if (count >= sizeof(uids))
		count = sizeof(uids) - 1;

	if (copy_from_user(uids, buffer, count))
		return -EFAULT;

	uids[count] = '\0';
	end_uid = uids;
	start_uid = strsep(&end_uid, "-");

	if (!start_uid || !end_uid)
		return -EINVAL;

	if (kstrtol(start_uid, 10, &start) != 0 ||
        kstrtol(end_uid, 10, &end) != 0) {
		return -EINVAL;
	}

#define UID_T_MAX (((uid_t)~0U)-1)
    if ((start < 0) || (end < 0) ||
        (start > UID_T_MAX) || (end > UID_T_MAX)) {
        return -EINVAL;
    }

    uid_start = start;
    uid_end = end;

    /* TODO need to unify uid_sys_stats interface with uid_time_in_state.
     * Here we are reusing remove_uid_range to reduce the number of
     * sys calls made by userspace clients, remove_uid_range removes uids
     * from both here as well as from cpufreq uid_time_in_state
     */
    cpufreq_task_stats_remove_uids(uid_start, uid_end);

	mutex_lock(&uid_lock);

	for (; uid_start <= uid_end; uid_start++) {
		hash_for_each_possible_safe(hash_table, uid_entry, tmp,
							hash, uid_start) {
			hash_del(&uid_entry->hash);
			kfree(uid_entry);
		}
	}

	mutex_unlock(&uid_lock);
	return count;
}

static const struct file_operations uid_remove_fops = {
	.open		= uid_remove_open,
	.release	= single_release,
	.write		= uid_remove_write,
};

static int process_notifier(struct notifier_block *self,
			unsigned long cmd, void *v)
{
	struct task_struct *task = v;
	struct uid_entry *uid_entry;
	cputime_t utime, stime;
	uid_t uid;

	if (!task)
		return NOTIFY_OK;

	mutex_lock(&uid_lock);
	uid = from_kuid_munged(current_user_ns(), task_uid(task));
	uid_entry = find_or_register_uid(uid);
	if (!uid_entry) {
		pr_err("%s: failed to find uid %d\n", __func__, uid);
		goto exit;
	}

	task_cputime_adjusted(task, &utime, &stime);
	uid_entry->utime += utime;
	uid_entry->stime += stime;
	uid_entry->power += task->cpu_power;
	task->cpu_power = ULLONG_MAX;

exit:
	mutex_unlock(&uid_lock);
	return NOTIFY_OK;
}

static struct notifier_block process_notifier_block = {
	.notifier_call	= process_notifier,
};

static int __init proc_uid_cputime_init(void)
{
	hash_init(hash_table);

	parent = proc_mkdir("uid_cputime", NULL);
	if (!parent) {
		pr_err("%s: failed to create proc entry\n", __func__);
		return -ENOMEM;
	}

	proc_create_data("remove_uid_range", S_IWUGO, parent, &uid_remove_fops,
					NULL);

	proc_create_data("show_uid_stat", S_IRUGO, parent, &uid_stat_fops,
					NULL);

	profile_event_register(PROFILE_TASK_EXIT, &process_notifier_block);

	return 0;
}

early_initcall(proc_uid_cputime_init);
