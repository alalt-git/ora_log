--
-- Create Schema Script 
--   Database Version          : 11.2.0.4.0 
--   Database Compatible Level : 11.2.0.4.0 
--   Script Compatible Level   : 11.2.0.4.0 
--   Toad Version              : 12.0.0.61 
--   DB Connect String         : DZMW_WORK 
--   Schema                    : PARUS 
--   Script Created by         : PARUS 
--   Script Created at         : 05/02/2021 17:16:50 
--   Physical Location         :  
--   Notes                     :  
--

-- Object Counts: 
--   Indexes: 1         Columns: 1          
--   Object Privileges: 1 
--   Packages: 1        Lines of Code: 38 
--   Package Bodies: 1  Lines of Code: 135 
--   Tables: 1          Columns: 16         Constraints: 2      


CREATE TABLE MCRD_SYNC_LOG
(
  RN             NUMBER                         NOT NULL,
  OPER           VARCHAR2(100 BYTE),
  STYPE          VARCHAR2(100 BYTE),
  REQ            CLOB,
  REQ_TIME       TIMESTAMP(6),
  RESULT         VARCHAR2(100 BYTE),
  RESP           CLOB,
  RESP_TIME      TIMESTAMP(6),
  PROCESS        CLOB,
  FLAG           NUMBER,
  ID_OBJ         VARCHAR2(200 BYTE),
  ENTITY         VARCHAR2(100 BYTE),
  DB_USER        VARCHAR2(100 BYTE),
  OSUSER         VARCHAR2(100 BYTE),
  ERROR_MSG      CLOB,
  HAVING_ERRORS  NUMBER
)
NOLOGGING 
/


CREATE UNIQUE INDEX C_MCRD_SYNC_LOG_PK ON MCRD_SYNC_LOG
(RN)
NOLOGGING
/


CREATE OR REPLACE PACKAGE pkg_mcrd_sync_log as
   -- Первичный лог
   -- Процедура создания сервисного лога
   procedure create_log(cXML in clob, sTYPE in varchar2);

   procedure create_process_log;
   -- Сеттеры
   procedure set_action(sACTION in varchar2);

   procedure set_result(sRESULT in varchar2);

   procedure set_resp(cRESP in clob);

   procedure set_resp_time;

   procedure set_idobj(sIDOBJ in varchar2);

   procedure set_entity(sENTITY in varchar2);

   procedure set_dbuser(sDBUSER in varchar2);

   procedure set_osuser(sOSUSER in varchar2);

   -- апдейт лога
   procedure update_log;

   procedure add_msg(sMSG in varchar2);

   procedure add_error(sMSG in varchar2);
   -- геттеры
   function getProcess return clob;

   function getRN return number;

   function getError return clob;


end;
/

CREATE OR REPLACE PACKAGE BODY pkg_mcrd_sync_log as

  gRN          NUMBER;                 -- rn сервис-лога
  gACTION      VARCHAR2(100);     -- операция
  gTYPE        VARCHAR2(100);      -- типа входящая/исходящая
  gREQ         CLOB;                   -- текст запроса
  gREQ_TIME    TIMESTAMP;              -- время формирования запроса
  gRESULT      VARCHAR2(100);      -- результат выполнения запроса
  gRESP        CLOB;                   -- текст ответа
  gRESP_TIME   TIMESTAMP;              -- время формирования ответа
  gPROCESS     CLOB;                   -- ход выполнения ПО
  gIDOBJ       varchar2(200);
  gENTITY      varchar2(100);
  gDBUSER      varchar2(100);
  gOSUSER      varchar2(100);
  gHAVERR      mcrd_sync_log.having_errors%type;

  -----
  gERROR       CLOB;                   -- файл с ошибками

   -- лог создается во время экспорта в Эталон
   procedure create_log(cXML in clob, sTYPE in varchar2) is
      pragma AUTONOMOUS_TRANSACTION;
   begin
      gRN         := gen_id;
      gACTION     := null;
      gTYPE       := sTYPE;
      gREQ        := cXML;
      gREQ_TIME   := systimestamp;
      gRESULT     := null;
      gRESP       := null;
      gRESP_TIME  := null;
      gERROR      := null;
      gHAVERR     := 0;
      -----
      insert into mcrd_sync_log(RN, sTYPE, REQ, REQ_TIME)
          values(gRN, gTYPE, gREQ, gREQ_TIME);
      commit;
   end;

   procedure create_process_log is
   begin
      dbms_output.put_line('Обнуление GPROCESS');
      gPROCESS := null;
   end;
   -- Сеттеры
   procedure set_action(sACTION in varchar2) is
   begin
      gACTION := sACTION;
   end;

   procedure set_result(sRESULT in varchar2) is
   begin
      gRESULT := sRESULT;
   end;

   procedure set_resp(cRESP in clob) is
   begin
      gRESP := cRESP;
   end;

   procedure set_resp_time is
   begin
      gRESP_TIME := systimestamp;
   end;

   procedure set_idobj(sIDOBJ in varchar2) is
   begin
      gIDOBJ := sIDOBJ;
   end;

   procedure set_entity(sENTITY in varchar2) is
   begin
      gENTITY := sENTITY;
   end;

   procedure set_dbuser(sDBUSER in varchar2) is
   begin
      gDBUSER := sDBUSER;
   end;

   procedure set_osuser(sOSUSER in varchar2) is
   begin
      gOSUSER := sOSUSER;
   end;

   -- апдейт лога
   procedure update_log is
      pragma AUTONOMOUS_TRANSACTION;
   begin
      update mcrd_sync_log
         set oper = gACTION
           , result = gRESULT
           , resp = gRESP
           , resp_time  = gRESP_TIME
           , process = gPROCESS
           , id_obj = gIDOBJ
           , entity = gENTITY
           , db_user = gDBUSER
           , osuser = gOSUSER
           , error_msg = gERROR
           , having_errors = gHAVERR
       where rn = gRN;
      commit;
   end;

   procedure add_msg(sMSG    in varchar2) is
   begin
     --gPROCESS := gPROCESS||sMSG||chr(10);
     gPROCESS := gPROCESS||to_char(systimestamp,'hh24:mi:ss.ff2')||' > '||sMSG||chr(10);
   end;

   procedure add_error(sMSG in varchar2) is
   begin
     --gERROR := gERROR||sMSG||chr(10);
     gHAVERR := gHAVERR + 1;
     gERROR := gERROR||to_char(systimestamp,'hh24:mi:ss.ff2')||' > '||sMSG||chr(10);
   end;

   function getProcess return clob is
   begin
      return gPROCESS;
   end;

   function getRN return number is
   begin
      return gRN;
   end;

   function getError return clob is
   begin
      return gERROR;
   end;

end;
/

ALTER TABLE MCRD_SYNC_LOG ADD (
  CONSTRAINT C_MCRD_SYNC_LOG_PK
  PRIMARY KEY
  (RN)
  USING INDEX C_MCRD_SYNC_LOG_PK
  ENABLE VALIDATE)
/


GRANT SELECT ON MCRD_SYNC_LOG TO PUBLIC
/