REM nvision_prioritisation_by_cumulative_runtime.sql
REM https://blog.psftdba.com/2023/11/prioritising-scheduled-processes-by.html

set serveroutput on
create or replace procedure sysadm.gfcprcspriority as
  PRAGMA AUTONOMOUS_TRANSACTION; 
  l_hist INTEGER := 61; --consider nVision processes going back this many days
begin
  EXECUTE IMMEDIATE 'truncate table ps_xx_gfcprcsprty';

--populate priorty table with known nVision processes 
insert /*+APPEND*/ into ps_ft_gfcprcsprty
with r as (
select r.prcstype, r.prcsname, r.prcsinstance, r.oprid, r.runcntlid, r.runstatus, r.servernamerun
, CAST(r.rqstdttm AS DATE) rqstdttm
, CAST(r.begindttm AS DATE) begindttm
, CAST(r.enddttm AS DATE) enddttm
from psprcsrqst r
  inner join ps.psdbowner p on r.dbname = p.dbname
where r.prcstype like 'nVision%' --limit to nVision processes
and r.prcsname = 'RPTBOOK' -- limit to report books
and r.enddttm>r.begindttm --it must have run to completion
and r.oprid IN('NVISION','NVISION2','NVISION3','NVISION4') --limit to overnight batch operator IDs
and r.begindttm >= TRUNC(SYSDATE)+.5-l_hist --consider process going back l_hist days from midday today
and r.runstatus = '9' --it has run to success
--and (TO_CHAR(r.begindttm,'HH24MI')>='1900' OR TO_CHAR(r.begindttm,'HH24MI')<='0500') 
and r.begindttm BETWEEN ROUND(r.begindttm)-5/24 AND ROUND(r.begindttm)+5/24 --run between 7pm and 5am
), x as (
select r.*, CEIL((enddttm-begindttm)*1440) duration
from r
), y as (
select prcstype, prcsname, oprid, runcntlid
, avg(duration) avg_duration
, MEDIAN(CEIL(duration)) med_duration
, MAX(duration) max_duration
, sum(CEIL(duration)) sum_duration
, count(*) num_samples
from x
group by prcstype, prcsname, oprid, runcntlid
), z as (
select y.* 
, sum(med_duration) over (order by med_duration rows between unbounded preceding and current row) cum_duration
, sum(med_duration) over () tot_duration
from y
)
select prcstype, prcsname, oprid, runcntlid 
--, CEIL(LEAST(tot_duration,cum_duration)/tot_duration*3)*4-3 prcsprty --3 priorities
, CEIL(LEAST(tot_duration,cum_duration)/tot_duration*9) prcsprty --9 priorities
--, NTILE(9) oveR (order by 0.0003125) prcsprty --evenly sized priorities
--, DENSE_RANK() OVER (order by med_duration) prcsprty
, avg_duration, med_duration, max_duration, cum_duration, tot_duration, num_samples
from z
order by prcsprty, cum_duration;

  dbms_output.put_line(sql%rowcount||' rows inserted');
  commit;

end gfcprcspriority;
/
show errors



