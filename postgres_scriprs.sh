#!/bin/bash
############################################################################################
# This is script collection to collect postgres # statistics based on the system tables.
# Information was taken from https://postgrespro.com/docs/postgrespro/9.5/monitoring-stats
# DATE: 11 July 2019
# Author: Maxim A.
############################################################################################

# Variables
metricname=$1
input=$2 # this is additional paramater, mainly to specify either DB name or table name.
connection="-h 127.0.0.1 -p 5432 -U postgres -d hybris"

# Metric Functions

CacheHit() {
        psql -qAtX $connection -c "select round(sum(blks_hit)*100/sum(blks_hit+blks_read), 2) from pg_stat_database"
}
UpTime() {
		psql -qAtX $connection -c "select date_part('epoch', now() - pg_postmaster_start_time())::int"
}
DBSize() {
		psql -qAtX $connection -c "select pg_database_size('$input')"
}
TableSize() {
		psql -qAtX $connection -c "select pg_relation_size('$input')"
}
IndexSize() {
		psql -qAtX $connection -c "select pg_total_relation_size('$input') - pg_relation_size('$input')"
}
NumBackends() {
		psql -qAtX $connection -c "select numbackends from pg_stat_database where datname = '$input'"
}
XActCommit() {
		psql -qAtX $connection -c "select xact_commit from pg_stat_database where datname = '$input'"
}
XActRollback() {
		psql -qAtX $connection -c "select xact_rollback from pg_stat_database where datname = '$input'"
}
BlkReads() {
		psql -qAtX $connection -c "select blks_read from pg_stat_database where datname = '$input'"
}
BlkHits() {
		psql -qAtX $connection -c "select blks_hit from pg_stat_database where datname = '$input'"
}
TupReturned() {
		psql -qAtX $connection -c "select tup_returned from pg_stat_database where datname = '$input'"
}
TupFetched() {
		psql -qAtX $connection -c "select tup_fetched from pg_stat_database where datname = '$input'"
}
TupInserted(){
		psql -qAtX $connection -c "select tup_inserted from pg_stat_database where datname = '$input'"
}
TupUpdated() {
		psql -qAtX $connection -c "select tup_updated from pg_stat_database where datname = '$input'"
}
DBStatConflicts() {
		psql -qAtX $connection -c "select conflicts from pg_stat_database where datname = '$input'"
}
TempFiles() {
		psql -qAtX $connection -c "select temp_files from pg_stat_database where datname = '$input'"
}
TempBytes() {
		psql -qAtX $connection -c "select temp_bytes from pg_stat_database where datname = '$input'"
}
Deadlocks() {
		psql -qAtX $connection -c "select deadlocks from pg_stat_database where datname = '$input'"
}
HeapBlksRead() {
		psql -qAtX $connection -c "select coalesce(heap_blks_read,0) from pg_statio_user_tables where (schemaname || '.' || relname) = '$input'"
}
HeapBlksHit() {
		psql -qAtX $connection -c "select coalesce(heap_blks_hit,0) from pg_statio_user_tables where (schemaname || '.' || relname) = '$input'"
}
IdxBlksRead() {
		psql -qAtX $connection -c "select coalesce(idx_blks_read,0) from pg_statio_user_tables where (schemaname || '.' || relname) = '$input'"
}
IdxBlkHit() {
		psql -qAtX $connection -c "select coalesce(idx_blks_hit,0) from pg_statio_user_tables where (schemaname || '.' || relname) = '$input'"
}
ToastBlkRead() {
		psql -qAtX $connection -c "select coalesce(toast_blks_read,0) from pg_statio_user_tables where (schemaname || '.' || relname) = '$input'"
}
ToastBlkHit() {
		psql -qAtX $connection -c "select coalesce(toast_blks_hit,0) from pg_statio_user_tables where (schemaname || '.' || relname) = '$input'"
}
TidxBlkRead() {
		psql -qAtX $connection -c "select coalesce(tidx_blks_read,0) from pg_statio_user_tables where (schemaname || '.' || relname) = '$input'"
}
TidxBlkHit() {
		psql -qAtX $connection -c "select coalesce(tidx_blks_hit,0) from pg_statio_user_tables where (schemaname || '.' || relname) = '$input'"
}
SeqScan() {
		psql -qAtX $connection -c "select coalesce(seq_scan,0) from pg_stat_user_tables where (schemaname || '.' || relname) = '$input'"
}
SeqTupRead() {
		psql -qAtX $connection -c "select coalesce(seq_tup_read,0) from pg_stat_user_tables where (schemaname || '.' || relname) = '$input'"
}
IdxScan() {
		psql -qAtX $connection -c "select coalesce(idx_scan,0) from pg_stat_user_tables where (schemaname || '.' || relname) = '$input'"
}
IdxTupFetch() {
		psql -qAtX $connection -c "select coalesce(idx_tup_fetch,0) from pg_stat_user_tables where (schemaname || '.' || relname) = '$input'"
}
TrxIdle(){
		psql -qAtX $connection -c "select coalesce(extract(epoch from max(age(now(), query_start))), 0) from pg_stat_activity where state='idle in transaction'"
}
TrxActive() {
		psql -qAtX $connection -c "select coalesce(extract(epoch from max(age(now(), query_start))), 0) from pg_stat_activity where state <> 'idle in transaction' and state <> 'idle'"
}
TrxWait() {
		if [ "$(psql -qAtX $1 -c 'show server_version_num')" -ge "090600" ]; then psql -qAtX $connection -c "select coalesce(extract(epoch from max(age(now(), query_start))), 0) from pg_stat_activity where wait_event is not null"; else psql -qAtX $connection -c "select coalesce(extract(epoch from max(age(now(), query_start))), 0) from pg_stat_activity where waiting IS TRUE"; fi
}
TrxPrepared() {
		psql -qAtX $connection -c "select coalesce(extract(epoch from max(age(now(), prepared))), 0) from pg_prepared_xacts"
}
AvgQueryTime() {
		psql -qAtX $connection -c "select round((sum(total_time) / sum(calls))::numeric,2) from pg_stat_statements"
}
# Here we will create selection tree.
case "$metricname" in
        cache_hit)
                printf '{"type":"integer", "name":"CacheUsage", "value":"%.0f%s"}\n' "$(CacheHit)"
                ;;
        uptime)
				secs=$(UpTime)
                #printf '{"type":"integer", "name":"UpTime", "value":"%dh:%dm:%ds"}\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60)) # This will convert output into string, thus requires conf file update.
                printf '{"type":"integer", "name":"UpTime", "value":"%s"}\n' "$secs"
                ;;
# Database Size, tables and indexes
        db_size)
                printf '{"type":"integer", "name":"DBSize", "value":"%s"}\n' "$(DBSize)"
                ;;
        table_size)
               printf '{"type":"integer", "name":"TableSize", "value":"%s"}\n' "$(TableSize)" 
                ;;
        index_size)
                printf '{"type":"integer", "name":"IndexSize", "value":"%s"}\n' "$(IndexSize)" 
                ;;
# Specific DB Statistics
        numb_backends)
                printf '{"type":"integer", "name":"NumBackends", "value":"%s"}\n' "$(NumBackends)"
                ;;
        xact_commit)
                printf '{"type":"integer", "name":"XActCommit", "value":"%s"}\n' "$(XActCommit)"
                ;;
        xact_rollback)
                printf '{"type":"integer", "name":"XActRollback", "value":"%s"}\n' "$(XActRollback)"
                ;;
        blks_read)
                printf '{"type":"integer", "name":"BlkReads", "value":"%s"}\n' "$(BlkReads)"
                ;;
        blks_hit)
                printf '{"type":"integer", "name":"BlkHits", "value":"%s"}\n' "$(BlkHits)"
                ;;
        tup_returned)
                printf '{"type":"integer", "name":"TupReturned", "value":"%s"}\n' "$(TupReturned)"
                ;;
         tup_fetched)
                printf '{"type":"integer", "name":"TupFetched", "value":"%s"}\n' "$(TupFetched)"
                ;;
        tup_inserted)
                printf '{"type":"integer", "name":"TupInserted", "value":"%s"}\n' "$(TupInserted)"
                ;;
        tup_update)
                printf '{"type":"integer", "name":"TupUpdated", "value":"%s"}\n' "$(TupUpdated)"
                ;;
        dbstat_conflicts)
                printf '{"type":"integer", "name":"DBStatConflicts", "value":"%s"}\n' "$(DBStatConflicts)"
                ;;
        temp_files)
                printf '{"type":"integer", "name":"TempFiles", "value":"%s"}\n' "$(TempFiles)"
                ;;
        temp_bytes)
                printf '{"type":"integer", "name":"TempBytes", "value":"%s"}\n' "$(TempBytes)"
                ;;
        deadlocks)
				printf '{"type":"integer", "name":"Deadlocks", "value":"%s"}\n' "$(Deadlocks)"
                ;;
# Table Statistics
        heap_blks_read)
            printf '{"type":"integer", "name":"HeapBlksRead", "value":"%s"}\n' "$(HeapBlksRead)"
                ;;
        heap_blks_hit)
            printf '{"type":"integer", "name":"HeapBlksHit", "value":"%s"}\n' "$(HeapBlksHit)"
                ;;
        idx_blks_read)
            printf '{"type":"integer", "name":"IdxBlksRead", "value":"%s"}\n' "$(IdxBlksRead)"
                ;;
        idx_blks_hit)
            printf '{"type":"integer", "name":"IdxBlkHit", "value":"%s"}\n' "$(IdxBlkHit)"
                ;;
        toast_blks_read)
            printf '{"type":"integer", "name":"ToastBlkRead", "value":"%s"}\n' "$(ToastBlkRead)"
                ;;
        toast_blks_hit)
            printf '{"type":"integer", "name":"ToastBlkHit", "value":"%s"}\n' "$(ToastBlkHit)"
                ;;
        tidx_blks_read)
            printf '{"type":"integer", "name":"TidxBlkRead", "value":"%s"}\n' "$(TidxBlkRead)"    
                ;;
        tidx_blks_hit)
            printf '{"type":"integer", "name":"TidxBlkHit", "value":"%s"}\n' "$(TidxBlkHit)" 
                ;;
        seq_scan)
            printf '{"type":"integer", "name":"SeqScan", "value":"%s"}\n' "$(SeqScan)"
                ;;
        seq_tup_read)
            printf '{"type":"integer", "name":"SeqTupRead", "value":"%s"}\n' "$(SeqTupRead)"
                ;;
        idx_scan)
            printf '{"type":"integer", "name":"IdxScan", "value":"%s"}\n' "$(IdxScan)"
                ;;
        idx_tup_fetch)
            printf '{"type":"integer", "name":"IdxTupFetch", "value":"%s"}\n' "$(IdxTupFetch)"
                ;;
# Transactions
        trx_idle)
            printf '{"type":"integer", "name":"TrxIdle", "value":"%s"}\n' "$(TrxIdle)"
                ;;
        trx_active)
            printf '{"type":"integer", "name":"TrxActive", "value":"%s"}\n' "$(TrxActive)"
                ;;
        trx_wait)
            printf '{"type":"integer", "name":"TrxWait", "value":"%s"}\n' "$(TrxWait)"
                ;;
        trx_prepared)
            printf '{"type":"integer", "name":"TrxPrepared", "value":"%s"}\n' "$(TrxPrepared)"
                ;;
        avg_query_time)
            printf '{"type":"integer", "name":"AvgQueryTime", "value":"%s"}\n' "$(AvgQueryTime)"
                ;;
            *)
        echo "00"
        ;;
esac
