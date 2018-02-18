---------------------------------------------------------
-- Document table
---------------------------------------------------------
drop table Documents purge;

CREATE TABLE Documents
  (
    ID                  NUMBER (30) NOT NULL ,
    Filename            VARCHAR2 (512 CHAR) NOT NULL ,
    FileTyp             VARCHAR2 (32 CHAR) ,
    FileDirectory       VARCHAR2 (2000 CHAR) NOT NULL ,
    FilePointer BFILE   NOT NULL ,
    MD5Hash             VARCHAR2 (32 CHAR) NOT NULL ,
    FileCreateDate      DATE ,
    FileLastModify      DATE ,
	FileLastAcess       DATE ,
	FILESIZE            number;
    Language            VARCHAR2 (32 CHAR) ,
    CreateDate          DATE default sysdate,
    CreateUser          VARCHAR2 (32 CHAR) default user,
    ChangeDate          DATE default sysdate,
    ChangeUser          VARCHAR2 (32 CHAR) default user,
    Theme_data_avaiable VARCHAR2 (1 CHAR)  DEFAULT 'N'
  ) ;

CREATE UNIQUE INDEX IDX_Documents_ID_PK ON Documents (  ID ASC );

ALTER TABLE Documents ADD CONSTRAINT Document_PK PRIMARY KEY ( ID ) ;

COMMENT ON TABLE Documents IS   'Store the file information' ;
COMMENT ON COLUMN Documents.ID IS  'Primary Key' ;
COMMENT ON COLUMN Documents.Filename IS  'Name of the file on disk' ;
COMMENT ON COLUMN Documents.FileTyp IS  'Typ of the file' ;
COMMENT ON COLUMN Documents.FileDirectory IS  'Directory of the file' ;
COMMENT ON COLUMN Documents.FilePointer IS  'Bfile Pointer to the File' ;
COMMENT ON COLUMN Documents.MD5Hash IS  'Hash of the files to indentify dublicate files' ;
COMMENT ON COLUMN Documents.FileCreateDate IS  'File Create Time from the file' ;
COMMENT ON COLUMN Documents.FileLastModify IS  'Last modificatoin date from the file' ;
COMMENT ON COLUMN Documents.FileLastAcess IS  'Last access time for this file';
COMMENT ON COLUMN Documents.FILESIZE IS  'File size';
COMMENT ON COLUMN Documents.Language IS  'Language of the file (Oracle NLS Format String!)' ;
COMMENT ON COLUMN Documents.CreateDate IS  'Date when the record was created' ;
COMMENT ON COLUMN Documents.CreateUser IS  'User create the record' ;
COMMENT ON COLUMN Documents.ChangeDate IS  'Last Change on the record' ;
COMMENT ON COLUMN Documents.ChangeUser IS  'User change the record' ;
COMMENT ON COLUMN Documents.Theme_data_avaiable IS  'If Themdata is there => Y, if not N' ;

---------------------------------------------------------
drop sequencE documents_seq;
create sequence documents_seq;