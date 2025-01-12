DECLARE
    L_BLOB           BLOB;
    L_CLOB           CLOB;
    L_DEST_OFFSET    INTEGER := 1;
    L_SRC_OFFSET     INTEGER := 1;
    L_LANG_CONTEXT   INTEGER := DBMS_LOB.DEFAULT_LANG_CTX;
    L_WARNING        INTEGER;
    L_LENGTH         INTEGER;
   P_SYSTEM_NAME_APP  varchar2(50)  := null;
BEGIN
    -- insert into XX_EMP_DEMO values(:P_COA_MAP_NAME,'def',NULL,NULL);
    -- commit;
    DBMS_LOB.CREATETEMPORARY(L_BLOB, FALSE);
    
    --get CLOB
--    WSC_CAHE_DOWNLOAD( L_CLOB,:P_COA_MAP_NAME);
-- insert into wsc_tbl_time_t (c) values(12344321);
-- commit;

        WSC_CCID_MISMATCH_REPORT.WSC_MISMATCH_CCID_DOWNLOAD(L_CLOB,:P_COA_MAP_ID);
    
    -- tranform the input CLOB into a BLOB of the desired charset
    DBMS_LOB.CONVERTTOBLOB( DEST_LOB     => L_BLOB,
                            SRC_CLOB     => L_CLOB,
                            AMOUNT       => DBMS_LOB.LOBMAXSIZE,
                            DEST_OFFSET  => L_DEST_OFFSET,
                            SRC_OFFSET   => L_SRC_OFFSET,
                            BLOB_CSID    => NLS_CHARSET_ID('WE8MSWIN1252'),
                            LANG_CONTEXT => L_LANG_CONTEXT,
                            WARNING      => L_WARNING
                          );

   
    L_LENGTH := DBMS_LOB.GETLENGTH(L_BLOB);  

 
    HTP.FLUSH;
    HTP.INIT;


    OWA_UTIL.MIME_HEADER( 'text/csv', FALSE);

    HTP.P('Content-length: ' || L_LENGTH);
    HTP.P('Content-Disposition: attachment; filename="WSC_MISMATCH_CACHE_DOWNLOAD.csv"');
    HTP.P('Set-Cookie: fileDownload=true; path=/');

    OWA_UTIL.HTTP_HEADER_CLOSE;

    WPG_DOCLOAD.DOWNLOAD_FILE( L_BLOB );

  EXCEPTION
    WHEN OTHERS THEN
      DBMS_LOB.FREETEMPORARY(L_BLOB);
      RAISE;
END;