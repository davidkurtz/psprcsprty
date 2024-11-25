REM process_prioritisation_by_cumulative_runtime.sql
REM https://blog.psftdba.com/2023/11/prioritising-scheduled-processes-by.html
clear screen
rollback;
set pages 99 lines 200 
spool process_prioritisation_by_cumulative_runtime

/*
DROP TRIGGER sysadm.psprcsque_set_prcsprty;
DROP TABLE sysadm.ps_xx_gfcprcsprty;
*/
REM table to hold specified priorities for specific run controls
--------------------123456789012345678
create table sysadm.ps_xx_gfcprcsprty
(prcstype  VARCHAR2(30 CHAR) NOT NULL
,prcsname  VARCHAR2(12 CHAR) NOT NULL
,oprid     VARCHAR2(30 CHAR) NOT NULL
,runcntlid VARCHAR2(30 CHAR) NOT NULL
,prcsprty  NUMBER NOT NULL
--------------------optional columns
,avg_duration NUMBER NOT NULL
,med_duration NUMBER NOT NULL
,max_duration NUMBER NOT NULL
,cum_duration NUMBER NOT NULL
,tot_duration NUMBER NOT NULL
,num_samples  NUMBER NOT NULL
) tablespace ptapp;

create unique index sysadm.ps_xx_gfcprcsprty
on sysadm.ps_xx_gfcprcsprty(prcstype, prcsname, oprid, runcntlid) 
tablespace psindex compress 3
/

truncate table sysadm.ps_xx_gfcprcsprty;

REM run script to set up metadata
@@nvision_prioritisation_by_cumulative_runtime.sql
--@@gppdprun_prioritisation_by_cumulative_runtime.sql

execute sysadm.gfcprcspriority;
select * from sysadm.ps_xx_gfcprcsprty
/



CREATE OR REPLACE TRIGGER sysadm.psprcsque_set_prcsprty
BEFORE INSERT /*OF prcsprty*/ ON sysadm.psprcsque
FOR EACH ROW
WHEN (new.prcsname = 'GPPDPRUN')
DECLARE
  l_prcsprty NUMBER;
BEGIN
  SELECT prcsprty
  INTO   l_prcsprty
  FROM   ps_xx_gfcprcsprty
  WHERE  prcstype = :new.prcstype
  AND    prcsname = :new.prcsname
  AND    oprid = :new.oprid
  AND    runcntlid = :new.runcntlid;
 
  :new.prcsprty := l_prcsprty;
EXCEPTION
  WHEN no_data_found THEN NULL;
  WHEN others THEN NULL;
END;
/
show errors

@@process_prioritisation_by_cumulative_runtime_test.sql
rollback;

--alter TRIGGER sysadm.psprcsque_set_prcsprty disable;
--DROP TRIGGER sysadm.psprcsque_set_prcsprty;

spool off


