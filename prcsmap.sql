REM prcsmap.sql
REM https://blog.psftdba.com/2023/11/prioritising-scheduled-processes-by.html
alter session set nls_date_format = 'DD/MM/YY hh24:MI:SS';
with t as (
--select TRUNC(SYSDATE)-19/24-0 begindttm
--,      TRUNC(SYSDATE)+5/24-0 enddttm
select TO_DATE('231020','YYMMDD') begindttm
,      SYSDATE enddttm
from dual
), r as (
select r.prcsinstance, r.oprid, r.runcntlid, r.runstatus, r.servernamerun, q.prcsprty
, CAST(r.rqstdttm AS DATE) rqstdttm
, CAST(r.rundttm AS DATE) rundttm
, CAST(r.begindttm AS DATE) begindttm
, CAST(r.enddttm AS DATE) enddttm
from psprcsrqst r
  left outer join psprcsque q on r.prcsinstance = q.prcsinstance
, t
where r.prcstype = 'COBOL SQL'
and r.prcsname = 'GPPDPRUN'
and r.begindttm < t.enddttm
and r.enddttm > t.begindttm
and r.begindttm > t.begindttm-1
)
select r.*
--, r.begindttm-TRUNC(t.begindttm) begintm
, r.rqstdttm-TRUNC(t.begindttm) rqsttm
, r.begindttm-r.rqstdttm qtime
, r.enddttm-r.begindttm duration
from r, t
order by r.begindttm
/
