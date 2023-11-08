REM process_prioritisation_by_cumulative_runtime_report.sql
spool process_prioritisation_by_cumulative_runtime_report.lst
clear screen
set pages 99 lines 200
break on prcsprty skip 1
column prcsinstance heading 'Process|Instance' format 99999999
column prcstype format a10
column prcsname format a10
column runcntlid format a20
column oprid format a10
colum prcsprty heading 'Prcs|Prty' format 99
column avg_duration format 999.99 heading 'Average|Duration|(mins)'
column med_duration format 9999 heading 'Median|Duration|(mins)'
column max_duration format 9999 heading 'Maximum|Duration|(mins)'
column tot_duration format 9999 heading 'Total|Duration|(mins)'
column cum_duration format 9999 heading 'Cum.|Median|Duration|(mins)'
column num_samples  format 999 heading 'Num|Runs'
column actual_prcsprty heading 'Last|Run|Prty' format 999
column actual_duration format 9999 heading 'Actual|Duration|(mins)'
column duration_diff format 9999 heading 'Median|Duration|Diff|(mins)'
column duration_pct format 9999 heading 'Median|Duration|%Diff'
column prtydiff format 999 heading 'Prty|Diff'
with r as (
select r.prcsinstance, r.prcstype, r.prcsname, r.oprid, r.runcntlid, q.prcsprty
, (r.enddttm-r.begindttm) duration
from psprcsrqst r, psprcsque q
where r.prcsinstance = q.prcsinstance
AND r.jobinstance IN(
  SELECT /*+UNNEST*/ MAX(r1.jobinstance) 
  FROM psprcsrqst r1
  WHERE r1.runstatus = '9' --it has run to success
  AND r1.enddttm>r1.begindttm --it must have run to completion
----------------------------------------------------------------------------------------------------
  and r1.oprid IN('NVISION','NVISION2','NVISION3','NVISION4') --limit to overnight batch operator IDs
  AND r1.prcstype like 'nVision%' --limit to nVision processes
  and r1.prcsname = 'RPTBOOK' -- limit to report books
  and r1.begindttm >= TRUNC(SYSDATE)+.5-61 --consider process going back l_hist days from midday today
--and r1.begindttm BETWEEN ROUND(r1.begindttm)-5/24 AND ROUND(r1.begindttm)+5/24 --run between 7pm and 5am
----------------------------------------------------------------------------------------------------
--and r1.oprid IN('batch') --limit to overnight batch operator IDs
--and r1.prcstype = 'COBOL SQL' --limit to gppdprun processes
--and r1.prcsname = 'GPPDPRUN' -- limit to report books
--and r1.jobinstance > 0
--and r1.runcntlid like 'GPPDPRUN_CALC______'
--and r1.begindttm >= TRUNC(SYSDATE)-1 --consider process going back 1 days 
----------------------------------------------------------------------------------------------------
GROUP BY r1.prcstype, r1.prcsname, r1.oprid, r1.runcntlid
  )
), x as (
select p.*
, r.prcsinstance
, r.prcsprty actual_prcsprty
, 60*extract(hour from r.duration)+extract(minute from r.duration)+CEIL(extract(second from r.duration)/60) actual_duration
from ps_xx_gfcprcsprty p
  left outer join r 
    on r.prcstype = p.prcstype
    AND r.prcsname = p.prcsname
    AND r.oprid = p.oprid
    AND r.runcntlid = p.runcntlid
)
select x.*
, x.actual_duration-x.med_duration duration_diff
, round(100*x.actual_duration/x.med_duration-100) duration_pct
, prcsprty-actual_prcsprty prtydiff
from x
where x.actual_duration!=x.med_duration OR x.actual_duration > 1 OR x.med_duration > 1 OR prcsprty!=actual_prcsprty
order by /*runcntlid,*/ prcsprty desc, med_duration desc, ABS(duration_diff) desc
/
spool off


