REM process_prioritisation_by_cumulative_runtime_test.sql
REM https://blog.psftdba.com/2023/11/prioritising-scheduled-processes-by.html

INSERT INTO psprcsque
(prcsinstance, prcstype, prcsname, oprid, runcntlid)
VALUES
(-42, 'COBOL SQL', 'GPPDPRUN', 'startup','GPPDPRUN_CALCUL_042');
INSERT INTO psprcsque
(prcsinstance, prcstype, prcsname, oprid, runcntlid)
VALUES
(-43, 'COBOL SQL', 'GPPDPRUN', 'startup','GPPDPRUN_CALCUL_043');
select prcsinstance, prcstype, prcsname, oprid, runcntlid, prcsprty from psprcsque where prcsinstance IN(-42,-43);
rollback;
