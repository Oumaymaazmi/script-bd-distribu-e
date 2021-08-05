//client_1 
create table client_1 as 
select no,nom, prenom ,adresse from 
client where ville='Marrakech'; 

// client_2
COPY TOen oum/Oumayma12@FST2 REPLACE client_2 USING select No,nom, prenom ,adresse from  client where ville='Casablanca'; 

//compte_1 
create table Compte_1 as 
select compte.no,Type_Compte_No,DateOuverture,Decouvert_autorise, Solde,
Client_No,Agence_No from 
compte, client_1 where compte.Client_No=client_1.no;

//compte_2
copy to oum/Oumayma12@Fst2 replace compte_2 using select * from compte where client_no IN (select no from client where ville = 'Casablanca');

//operation_1
create table operation_1 as select * from operation where compte_no IN (select no from compte_1);

//operation_2
copy to oum/Oumayma12@Fst2 replace operation_2 using select * from operation where compte_no NOT IN (select no from compte_1);

//type_compte_2
copy to oum/Oumayma12@Fst2  replace type_compte_2 using select * from type_compte;
//type_operation_2
copy to oum/Oumayma12@Fst2   replace type_operation_2 using select * from type_operation;

drop table operation;
drop table type_operation;
drop table compte;
drop table type_compte;
drop table client;



ALTER TABLE client_1 ADD PRIMARY KEY (no);
ALTER TABLE compte_1 ADD PRIMARY KEY (no);
ALTER TABLE operation_1 ADD PRIMARY KEY (no);

ALTER TABLE compte_1 ADD FOREIGN KEY (client_no) REFERENCES client_1(no);
ALTER TABLE compte_1 ADD FOREIGN KEY (Agence_No) REFERENCES agence(no);
ALTER TABLE operation_1 ADD FOREIGN KEY (Compte_No) REFERENCES compte_1(no);

ALTER TABLE client_2 ADD PRIMARY KEY (no);
ALTER TABLE compte_2 ADD PRIMARY KEY (no);
ALTER TABLE operation_2 ADD PRIMARY KEY (no);
ALTER TABLE type_operation_2 ADD PRIMARY KEY (no);
ALTER TABLE Type_Compte_2 ADD PRIMARY KEY (no);


ALTER TABLE compte_2  ADD FOREIGN KEY (client_no) REFERENCES client_2(no);
ALTER TABLE operation_2 ADD FOREIGN KEY (Type_Operation_No) REFERENCES type_operation_2(no);
ALTER TABLE operation_2 ADD FOREIGN KEY (Compte_No) REFERENCES compte_2(no);
ALTER TABLE compte_2  ADD FOREIGN KEY (Type_Compte_No) REFERENCES Type_Compte_2(no);


//compte_1 et Type_Compte_2
create or replace trigger fk_type_compte_compte_1
before insert or update   on compte_1 
for each row 
declare
cmpt integer :=0;
begin
  select count(*) into cmpt from type_compte_2@fst2 where no=:new.type_compte_no;
  if cmpt =0 then 
     raise_application_error(-20001,'fk violation into type_compte');
     
  end if;
end;
/

create or replace trigger drop_type_compte_1
before delete on type_compte_2
for each row 
declare
cmpt integer :=0;
begin
  select count(*) into cmpt from compte_1@fst1 where type_compte_no=:new.no;
  if cmpt !=0  then 
     raise_application_error(-20001,'fk violation into compte');
  end if;
end;
/

DELETE FROM type_compte_2 WHERE no=1;

 //operation_1 et type_operation_2 

create or replace trigger fk_type_operation
before insert or update   on operation_1 
for each row 
declare
cmpt integer :=0;
begin
  select count(*) into cmpt from type_operation_2@fst2 where no=:new.type_operation_no;
  if cmpt =0 then 
     raise_application_error(-20001,'fk violation into type_operation');
     
  end if;
end;
/

create or replace trigger drop_type_operation_2
before delete on type_operation_2
for each row 
declare 
cmpt integer :=0;
begin
  select count(*) into cmpt from compte_1@fst1 where type_compte_no=:new.no;
  if cmpt !=0  then 
     raise_application_error(-20001,'fk violation into opeartion');
  end if;
end;
/

// comte_2 et agence

create or replace trigger fk_agence
before insert or update   on compte_2
for each row 
declare
cmpt integer :=0;
begin
  select count(*) into cmpt from agence@fst1 where no=:new.agence_no;
  if cmpt =0 then 
     raise_application_error(-20001,'fk violation into agence');
     
  end if;
end;
/

create or replace trigger drop_agence
before delete on agence
for each row 
declare
cmpt integer :=0;
begin
  select count(*) into cmpt from compte_2@fst2 where agence_no=:new.no;
  if cmpt !=0  then 
     raise_application_error(-20001,'fk violation into compte_2');
  end if;
end;
/



//creation des databaseLink
create database link fst2 connect to oum identified by Oumayma12 using 'FST2';
create database link fst1 connect to oum identified by Oumayma12 using 'FST1';

create synonym client_1 for client_1@fst1;
create synonym compte_1 for compte_1@fst1;
create synonym operation_1 for operation_1@fst1;
create synonym agence for agence@fst1;
create synonym seq_client  for seq_client @fst1;
create synonym seq_agence  for seq_client @fst1;
create synonym seq_compte  for seq_client @fst1;
create synonym seq_operation  for seq_client @fst1;
create synonym seq_type_compte  for seq_client @fst1;
create synonym seq_type_operation  for seq_client @fst1;


create synonym client_2 for client_2@fst2;
create synonym compte_2 for compte_2@fst2;
create synonym operation_2 for operation_2@fst2;
create synonym type_compte for type_compte_2@fst2;
create synonym type_operation for type_operation_2@fst2;



create view client(no, nom, prenom, Adresse, Ville) as
select no, nom, prenom, Adresse,'Marrakech' from client_1 union select no, nom, prenom, Adresse,'Casablanca' from client_2;


create view compte as
select * from compte_1
union select * from compte_2;

create view operation as
select * from operation_1
union select * from operation_2;



create or replace trigger insert_client
instead of insert  on client
for each row 
declare
begin
  if :new.ville='Marrakech' then 
     insert into client_1 values(seq_client.nextval,:new.nom,:new.prenom,:new.adresse);
  elsif :new.ville='Marrakech' then 
    insert into client_2 values(seq_client.nextval,:new.nom,:new.prenom,:new.adresse);
  else
     raise_application_error(-20001,'faild insert client ');
  end if;
end;
/

create or replace trigger insert_compte
instead of insert  on compte
for each row 
declare
v_clint clien.ville%type
begin
  select ville into v_clint from client where no=:new.client_no;
  if v_clint='Marrakech' then 
     insert into compte_1 values(seq_compte.nextval,:new.Type_Compte_No, :new.DateOuverture, :new.Decouvert_autorise, :new.Solde,:new.Client_No, :new.Agence_No);
  elsif v_clint='Casablanca' then 
     insert into compte_2 values(seq_compte.nextval,:new.Type_Compte_No, :new.DateOuverture, :new.Decouvert_autorise, :new.Solde,:new.Client_No, :new.Agence_No);
  else
     raise_application_error(-20001,'faild insert compte');
  end if;
end;
/
create database link fst2 
create or replace trigger insertoperation
instead of insert  on operation
for each row 
declare
v_clint clien.ville%type
soldeCompte integer;
decouvertAutoriser integer;
begin
  select ville into v_clint from client where no in (select client_no from compte where no =:new.comte_no);
  select solde into soldeCompte from comte where no = :new.comte_no;
   select Decouvert_autorise into decouvertAutoriser from compte where no= :new.Compte_No;

  if v_clint='Marrakech ' then 
      if :new.Type_Operation_No=1 then 
         update compte_1 set solde=solde+:new.montant where no = :new.Compte_No;
      elsif :new.Type_Operation_No=2 then
         if :new.montant > soldeCompte +decouvertAutoriser then raise raise_application_error(-20000, 'impossible montant entre');;
         elsif :new.montant <soldeCompte then 
            update compte_1 set solde=soldeCompte-:new.montant where no = Compte_No;
         else
            update compte_1 set solde=:new.montant-soldeCompte where no = Compte_No;
     
         end if; 
      
      end if;
      insert into operation_1 values(seq_operation.nextval,:new.Type_Operation_No,:new.Compte_No,:new.montant);
   elsif villeClient='Casablanca' then
     if :new.Type_Operation_No=1 then 
         update compte_2 set solde=solde+:new.montant where no = :new.Compte_No;
      elsif :new.Type_Operation_No=2 then
         if :new.montant > soldeCompte +decouvertAutoriser then raise raise_application_error(-20000, 'impossible montant entre');;
         elsif :new.montant <soldeCompte then 
            update compte_2 set solde=soldeCompte-:new.montant where no = Compte_No;
         else
            update compte_2 set solde=:new.montant-soldeCompte where no = Compte_No;
     
         end if; 
      
      end if;
      insert into operation_2 values(seq_operation.nextval,:new.Type_Operation_No,:new.Compte_No,:new.montant);
end;
/

DROP VIEW  client ;
create user oum IDENTIFIED by Oumayma12;
GRANT all PRIVILEGE TO oum;


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

create or replace procedure  insetclient( nom varchar2, prenom varchar2, Adresse varchar2, Ville varchar2)
is  
exeptionVille EXCEPTION;
begin

if ville= 'Marrakech' then 
      insert into client_1 values(seq_client.nextval,nom,prenom,adresse);
elsif ville='Casablanca' then 
      insert into client_2 values(seq_client.nextval,nom,prenom,adresse);
else 
   raise exeptionVille;
end if;
dbms_output.put_line('client est crée ');

EXCEPTION 
  when exeptionVille then DBMS_OUTPUT.PUT_LINE('pas de ville ' ) ;
END;
/

call insetclient('tata','nbnb','benimella','Marrakech');
call insetclient('oum','azmi','benimella','beniMellal');



create or replace procedure  insetCompte(Type_Compte_No number, DateOuverture Date, Decouvert_autorise number, Solde number,client_No number, Agence_No number)
is 
exeptionVille EXCEPTION;
villeClient client.ville%type;
compteurClient integer:=0;
compteurTypeCompte integer:=0;
compteurAgenceCompte integer:=0;

clientExecption exception;
typeComteExecption exception;
agenceExecption exception;
villeExeption EXCEPTION;

begin
select count(no) into compteurClient from client where no = client_No;
select count(no) into compteurTypeCompte from type_compte_2 where no = Type_Compte_No;
select count(no) into compteurAgenceCompte from agence where no = Agence_No;

if compteurClient=0 then raise clientExecption;
elsif    compteurTypeCompte=0 then raise typeComteExecption;
elsif compteurAgenceCompte=0 then raise agenceExecption;
else 
  select ville into villeClient from client where no = client_No;
  if villeClient='Marrakech ' then
      insert into compte_1 values(seq_compte.nextval,Type_Compte_No,DateOuverture,Decouvert_autorise, Solde,Client_No,Agence_No);
   elsif villeClient ='Casablance' then
      insert into compte_2 values(seq_compte.nextval,Type_Compte_No,DateOuverture,Decouvert_autorise, Solde,Client_No,Agence_No);
   else 
      raise villeExeption;
   end if;
end if;
EXCEPTION 
  when clientExecption then dbms_output.put_line('pas de client ');
  when typeComteExecption then dbms_output.put_line('pas de typeComte ');
  when agenceExecption then dbms_output.put_line('pas de agencd ');
  when villeExeption then dbms_output.put_line('pas de ville ');
END;
/

ALTER TABLE operation_1 ADD montant number;
ALTER TABLE operation_2 ADD montant number;
drop view opeartion;



create or replace procedure insertOperation(Type_Operation_No number , Compte_No number ,montant number)
is 
compteurTypeOperation integer;
compteurCompte integer;
villeClient client.ville%type;
decouvertAutoriser compte.Decouvert_autorise%type;
soldeCompte compte.solde%type;

compteExecption exception;
typeOperationExecption exception;
villeExeption EXCEPTION;
soldeException EXCEPTION;

begin

select count(no) into compteurTypeOperation from type_operation where no= Type_Operation_No;
select count(no) into compteurCompte from compte where no= Compte_No;

if compteurTypeOperation =0 then raise typeOperationExecption;
elsif compteurCompte=0 then raise compteExecption;
else 
   select ville into villeClient from client where no in (select client_No from compte where no=Compte_No ); 
   select Decouvert_autorise into decouvertAutoriser from compte where no= Compte_No;
   select solde into soldeCompte from compte where no= Compte_No;

   if villeClient='Marrakech ' then 
      if Type_Operation_No=1 then 
         update compte_1 set solde=soldeCompte+montant where no = Compte_No;
      elsif Type_Operation_No=2 then
         if montant > soldeCompte +decouvertAutoriser then raise soldeException;
         elsif montant <soldeCompte then 
            update compte_1 set solde=soldeCompte-montant where no = Compte_No;
         else
            update compte_1 set solde=montant-soldeCompte where no = Compte_No;

         end if; 
      
      end if;
      insert into operation_1 values(seq_operation.nextval,Type_Operation_No,Compte_No,montant);
   elsif villeClient='Casablanca' then
      if Type_Operation_No=1 then 
         update compte_2 set solde=soldeCompte+montant where no = Compte_No;
      elsif Type_Operation_No=2 then
         if montant > soldeCompte +decouvertAutoriser then raise soldeException;
         elsif montant <soldeCompte then 
            update compte_2 set solde=soldeCompte-montant where no = Compte_No;
         else
            update compte_2 set solde=montant-soldeCompte where no = Compte_No;
     
         end if; 
    
      end if;
      insert into operation_2 values(seq_operation.nextval,Type_Operation_No,Compte_No,montant);
   else 
      raise villeExeption;
   end if; 
end if;
exception
     when villeExeption then dbms_output.put_line('pas de ville ');
     when compteExecption then dbms_output.put_line('pas de compte ');
     when typeOperationExecption then dbms_output.put_line('pas de typeOperation ');
     when soldeException then dbms_output.put_line('erreur solde ');
end;
/
   




===>duplication Synchrone
create table TYPE_PRET (Type_prêt VARCHAR(10),Nom_type_prêt VARCHAR(20),Maximum_autorisé NUMBER(8));
alter table TYPE_PRET add constraint Type_prêt primary key (Type_prêt);

insert into TYPE_PRET values('p1','pret pour les jeune',20000);
insert into TYPE_PRET values('p2','pret variables',10000);
insert into TYPE_PRET values('p3','pret fixes',30000);

copy from oum/oumayma12@fst1 to oum/oumayma12@fst2 replace TYPE_PRET using select * from TYPE_PRET;

create or replace trigger syn_type_pret before insert or update or delete on  TYPE_PRET 
for each row
declare
exist number;
begin
if inserting then
select count(*) into exist from TYPE_PRET where Type_prêt=:new.Type_prêt;
if exist<>0 then
raise_application_error(-20001,'duplication of primary key');
end if;
insert into TYPE_PRET@fst2 values(:new.Type_prêt,:new.Nom_type_prêt,:new.Maximum_autorisé);
end if;
if updating then
if updating Nom_type_prêt then 
update TYPE_PRET@fst2 set Nom_type_prêt=:new.Nom_type_prêt where Type_prêt=:old.Type_prêt;
elif updating Maximum_autorisé then
update TYPE_PRET@fst2 set Maximum_autorisé =:new.Maximum_autorisé  where Type_prêt=:old.Type_prêt;
end if;
end if;
if deleting then
delete from TYPE_PRET@fst2 where Type_prêt=:old.Type_prêt;
end if;
end;
/


===>Duplication Asynchrone
truncate table TYPE_PRET;
CREATE SNAPSHOT TYPE_PRET
REFRESH FAST
START WITH SYSDATE
NEXT SYSDATE + 10
AS Select * from TYPE_PRET@fst1;

create table Attente(Numéro NUMBER,Ordre VARCHAR(400));
alter table Attente add constraint Attente primary key (Numéro);
create sequence SEQ_ATT;


create sequence SEQ_ATT START WITH 1 INCREMENT BY 1;
create or replace trigger TRIG_ATT before insert or update or delete on TYPE_PRET
for each row
declare 
begin
if inserting then
insert into Attente value(SEQ_ATT.nextval,' insert into TYPE_PRET values(' || :new.Type_prêt || ',' || :new.Nom_type_prêt || ',' || :new.Maximum_autorisé || ')');
end if;
if updating then
insert into Attente value(SEQ_ATT.nextval,'update TYPE_PRET set Nom_type_prêt=' || :new.Nom_type_prêt || ', Maximum_autorisé= ' || :new.Maximum_autorisé
|| 'where Type_prêt=' || :old.Type_prêt);
end if;
if deleting then 
insert into Attente value(SEQ_ATT.nextval,'delete from TYPE_PRET where Type_prêt=' || :old.Type_prêt);
end if;
end;
/




create or replace trigger recu_Maj_on_typepret 
before insert or update or delete  on TYPE_PRET
for each row 
begin 
if inserting then 
insert into Attente values(SEQ_ATT.nextval,' insert into TYPE_PRET@fst2 values('||chr(39) || :new.Type_prêt || chr(39)||',' ||chr(39)|| :new.Nom_type_prêt ||chr(39)|| ','|| :new.Maximum_autorisé || ')');
end if; 
if updating then 
insert into Attente values(SEQ_ATT.nextval,' update TYPE_PRET@fst2 set Nom_type_prêt=' ||chr(39) || :new.Nom_type_prêt ||chr(39)|| ', Maximum_autorisé='|| :new.Maximum_autorisé || ')');
end if;
if deleting then 
insert into Attente values(SEQ_ATT.nextval,'delete from TYPE_PRET@fst2 where Type_prêt=' ||chr(39) || :old.Type_prêt||chr(39) ||')');
end if;
end ;
/


create or replace procedure EXE_ORDRES  
is 
begin 
for a in (select * from attente ) loop
  execute immediate a.Ordre;
  delete from attente where Numéro= a.Numéro;
end loop;
commit;
end;
/

execute EXE_ORDRES ;


insert into TYPE_PRET values('p1','pret pour les jeune',20000);
insert into TYPE_PRET values('p2','pret variables',10000);
insert into TYPE_PRET values('p3','pret fixes',30000);

variable  x number ;
execute dbms_job.submit(:x,'exe_ordres;',sysdate,'sysdate + 1,6');


CREATE SNAPSHOT LOG ON type_pret;

CREATE SNAPSHOT Image_type_pret
		REFRESH FAST
		START WITH SYSDATE
		NEXT SYSDATE + 1.6
		AS Select * from type_pret@fst1;

select  * from Image_type_pret;



CREATE TABLE TYPE_PRET(
		type_pret  NUMBER(2) PRIMARY KEY,
		nom_type_pret VARCHAR2(20),
		maximum_autorise NUMBER(8),
		jeton char(1)
		);
CREATE SEQUENCE SEQ_PRET order;

CREATE VIEW VTYPE_PRET (type_pret,nom_type_pret,maximum_autorise,jeton) 
AS SELECT * FROM TYPE_PRET;

COPY  to oum/Oumayma12@fst2 replace TYPE_PRET USING SELECT * FROM TYPE_PRET;

--- On FST2 Crete synonym for seq_pret
CREATE SYNONYM SEQ_PRET FOR SEQ_PRET@FST1;

CREATE VIEW VTYPE_PRET (type_pret,nom_type_pret,maximum_autorise,jeton) 
AS SELECT * FROM TYPE_PRET;

------- Creation des trigger d'insertion ----------
------fst1------------------
CREATE OR REPLACE TRIGGER TRG_REPLICATION_insert 
INSTEAD OF INSERT ON VTYPE_PRET
FOR EACH ROW 
BEGIN
IF  :new.jeton IS NULL THEN
	INSERT INTO TYPE_PRET VALUES(:new.type_pret,:new.nom_type_pret,:new.maximum_autorise,:new.jeton);
	INSERT INTO VTYPE_PRET@FST2 VALUES(:new.type_pret,:new.nom_type_pret,:new.maximum_autorise,'1');
	dbms_output.put_line('after inserting in VTYPE_PRET@fst2');
ELSIF :new.jeton = '2' THEN 
	INSERT INTO TYPE_PRET VALUES(:new.type_pret,:new.nom_type_pret,:new.maximum_autorise,:new.jeton);
END IF;
END;
/
-- FST2--------------
CREATE OR REPLACE TRIGGER TRG_REPLICATION_insert
INSTEAD OF INSERT ON VTYPE_PRET
FOR EACH ROW 
BEGIN
IF :new.jeton IS NULL  THEN
	INSERT INTO TYPE_PRET VALUES(:new.type_pret,:new.nom_type_pret,:new.maximum_autorise,:new.jeton);
	INSERT INTO VTYPE_PRET@FST1 VALUES(:new.type_pret,:new.nom_type_pret,:new.maximum_autorise,'2');
ELSIF :new.jeton = '1' THEN 
	INSERT INTO TYPE_PRET VALUES(:new.type_pret,:new.nom_type_pret,:new.maximum_autorise,:new.jeton);
END IF;
END;
/
----- TEST -----------
INSERT INTO VTYPE_PRET VALUES(SEQ_PRET.nextval,'TEST',120,NULL);




------- Creation des trigger deleting ----------
---- create function pour le count des ligne avant le delet ------------
create or replace function countdeletType(v_type in NUMBER) RETURN number  
as
cmpt integer :=0;
begin
select count(TYPE_PRET) into cmpt from VTYPE_PRET where TYPE_PRET = v_type;
 RETURN cmpt;
end;
/
-----fst1---------

CREATE OR REPLACE TRIGGER TRG_REPLICATION_delet 
INSTEAD OF DELETE ON VTYPE_PRET
FOR EACH ROW 
declare
cmpt integer;
BEGIN
cmpt := countdeletType(:old.type_pret);
----- if la ligne exite on va delete si non ova areter la boucle -------
if cmpt > 0 then 
 IF :old.jeton IS NULL or :old.jeton = '2' THEN
	DELETE FROM TYPE_PRET WHERE type_pret= :old.type_pret;
	DELETE FROM VTYPE_PRET@fst2 WHERE type_pret= :old.type_pret;
 END IF;
end if;
END;
/
---fst2-----
CREATE OR REPLACE TRIGGER TRG_REPLICATION_delet 
INSTEAD OF DELETE ON VTYPE_PRET
FOR EACH ROW 
declare
cmpt integer;
BEGIN
cmpt := countdeletType(:old.type_pret);
if cmpt > 0 then 
 IF :old.jeton IS NULL or :old.jeton = '1' THEN
	DELETE FROM TYPE_PRET WHERE type_pret= :old.type_pret;
	DELETE FROM VTYPE_PRET@fst1 WHERE type_pret= :old.type_pret;
 END IF;
end if;
END;
/
---test----
	DELETE FROM VTYPE_PRET WHERE type_pret= 68;

------- Creation des trigger uodating  ----------
----------fst1-------

CREATE OR REPLACE TRIGGER TRG_REPLICATION_maj
INSTEAD OF update ON VTYPE_PRET
FOR EACH ROW 
declare 
test_new_nom  VARCHAR2(20);
test_new_max NUMBER(8);
BEGIN
if :old.jeton = :new.jeton or (:old.jeton is NULL and :new.jeton is NULL ) then 
    if :old.jeton is NULL then
	   dbms_output.put_line('jeton null');
       update   TYPE_PRET set  nom_type_pret= :new.nom_type_pret,maximum_autorise=:new.maximum_autorise 
		where type_pret=:old.type_pret;
       update   VTYPE_PRET@fst2  set  nom_type_pret= :new.nom_type_pret,maximum_autorise=:new.maximum_autorise 
		where type_pret=:old.type_pret;
	elsif  :old.jeton ='2'  then
	---- pour garder la transparence on va tester si la reque from locale ou distant 
    -------- par test si les rebrique on etai deja modifie sur le site distans si oui la requet distant si non la requet et locale
        select nom_type_pret INTO test_new_nom  FROM vtype_pret@fst2 where type_pret=:old.type_pret;
		select maximum_autorise INTO test_new_max FROM vtype_pret@fst2 where type_pret=:old.type_pret;
		dbms_output.put_line(test_new_nom);

		if test_new_nom != :new.nom_type_pret or test_new_max!= :new.maximum_autorise then
		    dbms_output.put_line('fst1 badlha ');
		    update   TYPE_PRET set  nom_type_pret= :new.nom_type_pret,maximum_autorise=:new.maximum_autorise ,jeton=NULL
		       where type_pret=:old.type_pret;
	        update   VTYPE_PRET@fst2  set  nom_type_pret= :new.nom_type_pret,maximum_autorise=:new.maximum_autorise ,jeton='1'
		       where type_pret=:old.type_pret;
			dbms_output.put_line('updating 3adiya f fst2  ');			
		else 
		    dbms_output.put_line('fst2 badlha ');
			update   TYPE_PRET set  nom_type_pret= :new.nom_type_pret,maximum_autorise=:new.maximum_autorise 
		       where type_pret=:old.type_pret;
	       
		end if;
	  	dbms_output.put_line('updating done ');
	end if ;
else 
   update   TYPE_PRET set  nom_type_pret= :new.nom_type_pret,maximum_autorise=:new.maximum_autorise ,jeton = :new.jeton
		where type_pret=:old.type_pret;
 
end if; 
END;
/
-------------fst2-----------------------
CREATE OR REPLACE TRIGGER TRG_REPLICATION_maj
INSTEAD OF update ON VTYPE_PRET
FOR EACH ROW 
declare 
test_new_nom  VARCHAR2(20);
test_new_max NUMBER(8);
BEGIN
if :old.jeton = :new.jeton or (:old.jeton is NULL and :new.jeton is NULL ) then 
	dbms_output.put_line('ana dkhalt ');
    if :old.jeton is NULL then
	   dbms_output.put_line('jeton null');
       update   TYPE_PRET set  nom_type_pret= :new.nom_type_pret,maximum_autorise=:new.maximum_autorise 
		where type_pret=:old.type_pret;
       update   VTYPE_PRET@fst1  set  nom_type_pret= :new.nom_type_pret,maximum_autorise=:new.maximum_autorise 
		where type_pret=:old.type_pret;
	elsif  :old.jeton ='1'  then
        select nom_type_pret INTO test_new_nom  FROM vtype_pret@fst1 where type_pret=:old.type_pret;
		select maximum_autorise INTO test_new_max FROM vtype_pret@fst1 where type_pret=:old.type_pret;
		dbms_output.put_line(test_new_nom);

		if test_new_nom != :new.nom_type_pret or test_new_max!= :new.maximum_autorise then
		    dbms_output.put_line('fst2 badlha ');
		    update   TYPE_PRET set  nom_type_pret= :new.nom_type_pret,maximum_autorise=:new.maximum_autorise ,jeton=NULL
		       where type_pret=:old.type_pret;
	        update   VTYPE_PRET@fst1  set  nom_type_pret= :new.nom_type_pret,maximum_autorise=:new.maximum_autorise ,jeton='2'
		       where type_pret=:old.type_pret;			
		else 
		    dbms_output.put_line('fst1 badlha ');
			update   TYPE_PRET set  nom_type_pret= :new.nom_type_pret,maximum_autorise=:new.maximum_autorise 
		      where type_pret=:old.type_pret;
		end if;
    end if ;
else 
   update TYPE_PRET set  nom_type_pret= :new.nom_type_pret, maximum_autorise=:new.maximum_autorise ,jeton ='1'
		where type_pret=:old.type_pret;
end if;

END;
/
--- test ----
update   VTYPE_PRET set  nom_type_pret= 'last  ' where type_pret=5;

