## Backup Policy

- Two servers are maintained with a, currently manual, failover mechanism. 
    - The first priority is no data loss (user info etc.)
    - The second priority is to minimize down time.

```note
Over time, it is planned to move this to an automatic failover.
```

- User data and cached posts and images are maintained in this backup on a local redundant file server.
- Rolling offsite backups are also made at a lower frequency.