-----------------------------------------------------------------------------
--
--  Logical unit: CEACustomizationUtil
--  Component:    CONFIG
--
--  IFS Developer Studio Template Version 3.0
--
--  Date    Sign    History
--  ------  ------  ---------------------------------------------------------
-----------------------------------------------------------------------------

layer Core;

-------------------- PUBLIC DECLARATIONS ------------------------------------


-------------------- PRIVATE DECLARATIONS -----------------------------------


-------------------- LU SPECIFIC IMPLEMENTATION METHODS ---------------------


-------------------- LU SPECIFIC PRIVATE METHODS ----------------------------


-------------------- LU SPECIFIC PROTECTED METHODS --------------------------


-------------------- LU SPECIFIC PUBLIC METHODS -----------------------------
--C0392 EntPrageG (START)

PROCEDURE Bulk_Update_Invoice_Header_Notes__(
   company_  IN VARCHAR2,
   identity_ IN VARCHAR2)
IS
   stmt_ VARCHAR2(32000);   
BEGIN
   stmt_ :='
      DECLARE
         invoice_header_notes_rec_ invoice_header_notes_tab%ROWTYPE;
         
         CURSOR bulk_update_notes_(company_ VARCHAR2, identity_ VARCHAR2) IS
            SELECT *
              FROM invoice_header_notes_cfv
             WHERE company = company_
               AND identity = identity_
               AND cf$_bulk_update_db = ''TRUE''
               AND cf$_bulk_update_user = Fnd_Session_API.Get_Fnd_User;
                 
         CURSOR bulk_update_ledger_items_ (company_ VARCHAR2, identity_ VARCHAR2, invoice_id_ NUMBER) IS
            SELECT *
              FROM ledger_item_cu_det_qry_cfv
             WHERE company = company_
               AND identity = identity_        
               AND invoice_id != invoice_id_ -- if the invoice id similar no need to insert again
               AND cf$_bulk_update IS NOT NULL
               AND cf$_bulk_update_user = Fnd_Session_API.Get_Fnd_User;

         FUNCTION Get_Party_Type___ (
            objkey_ VARCHAR2) RETURN VARCHAR2
         IS
            party_type_ VARCHAR2(20);
         BEGIN
            SELECT party_Type
              INTO party_type_
              FROM invoice_header_notes
             WHERE objkey = objkey_;
            RETURN party_type_;
         EXCEPTION
            WHEN OTHERS THEN
               RETURN NULL;
         END Get_Party_Type___;

         FUNCTION Get_Invoice_Header_Note___ (
            company_    IN VARCHAR2,
            invoice_id_ IN VARCHAR2,
            note_id_    IN VARCHAR2) RETURN invoice_header_notes_tab%ROWTYPE
         IS
          rec_ invoice_header_notes_tab%ROWTYPE;
         BEGIN
            SELECT company,
                 invoice_id,
                 identity,
                 party_type,
                 note_date,
                 note_text,
                 credit_analyst,
                 user_id,
                 cust_contact_name,
                 cust_telephone_number,
                 follow_up_date,note_status_id
            INTO rec_.company,
                 rec_.invoice_id,
                 rec_.identity,
                 rec_.party_type,
                 rec_.note_date,
                 rec_.note_text,
                 rec_.credit_analyst,
                 rec_.user_id,
                 rec_.cust_contact_name,
                 rec_.cust_telephone_number,
                 rec_.follow_up_date,
                 rec_.note_status_id
            FROM invoice_header_notes_tab
            WHERE company = company_
             AND invoice_id = invoice_id_
             AND note_id = note_id_;
            RETURN rec_;
         EXCEPTION
            WHEN no_data_found THEN
               RETURN rec_;
         END Get_Invoice_Header_Note___;

         FUNCTION Get_Note_Id___(
            company_    IN VARCHAR2,
            invoice_id_ IN NUMBER) RETURN NUMBER
         IS
            note_id_ NUMBER;
         BEGIN
            SELECT NVL(MAX(note_id), 0) + 1
             INTO note_id_
             FROM invoice_header_notes
            WHERE company = company_
              AND invoice_id = invoice_id_;
            RETURN note_id_;
         EXCEPTION
            WHEN no_data_found THEN
               RETURN 1;
         END Get_Note_Id___;

         FUNCTION Get_Attr___(
            invoice_id_ IN NUMBER,
            rec_        IN invoice_header_notes_tab%ROWTYPE) RETURN VARCHAR2
         IS
            attr_ VARCHAR2(32000);
         BEGIN
            DBMS_OUTPUT.put_line(rec_.rowkey);
            Client_SYS.Clear_Attr(attr_);
            Client_SYS.Add_To_Attr(''COMPANY'', rec_.company, attr_);
            Client_SYS.Add_To_Attr(''IDENTITY'', rec_.identity, attr_);
            Client_SYS.Add_To_Attr(''PARTY_TYPE'', rec_.party_type, attr_);
            Client_SYS.Add_To_Attr(''INVOICE_ID'', invoice_id_, attr_);
            Client_SYS.Add_To_Attr(''NOTE_ID'', get_note_id___(rec_.company,invoice_id_), attr_);
            Client_SYS.Add_To_Attr(''NOTE_DATE'', rec_.note_date, attr_);
            Client_SYS.Add_To_Attr(''NOTE_TEXT'', rec_.note_text, attr_);
            Client_SYS.Add_To_Attr(''CREDIT_ANALYST'', rec_.credit_analyst, attr_);
            Client_SYS.Add_To_Attr(''USER_ID'', rec_.user_id, attr_);
            Client_SYS.Add_To_Attr(''CUST_CONTACT_NAME'', rec_.cust_contact_name, attr_);
            Client_SYS.Add_To_Attr(''CUST_TELEPHONE_NUMBER'', rec_.cust_telephone_number, attr_);
            Client_SYS.Add_To_Attr(''FOLLOW_UP_DATE'', rec_.follow_up_date, attr_);
            Client_SYS.Add_To_Attr(''NOTE_STATUS_ID'', rec_.note_status_id, attr_);
            Client_SYS.Add_To_Attr(''ROWVERSION'', SYSDATE, attr_);
         RETURN attr_;
         END Get_Attr___;

         FUNCTION Get_Attr___ (
            query_reason_ IN VARCHAR2) RETURN VARCHAR2
         IS
            attr_ VARCHAR2(32000);
         BEGIN
            Client_SYS.Clear_Attr(attr_);
            Client_SYS.Add_To_Attr(''CF$_QUERY_REASON_DB'', query_reason_, attr_);
            RETURN attr_;
         END Get_Attr___;

         PROCEDURE Add_Header_Note___(
            invoice_id_   IN NUMBER,
            query_reason_ IN VARCHAR2,
            rec_          IN invoice_header_notes_tab%ROWTYPE)
         IS
            attr_  VARCHAR2(32000);
            attr_cf_  VARCHAR2(32000);
            info_  VARCHAR2(32000);
            objid_ VARCHAR2(50);
            objversion_ VARCHAR2(50);
         BEGIN
            attr_:= Get_Attr___(invoice_id_,rec_);
            attr_cf_ := Get_Attr___(query_reason_);

            Invoice_Header_Notes_API.New__(info_,objid_,objversion_,attr_,''DO'');
            IF query_reason_ IS NOT NULL THEN
              Invoice_Header_Notes_CFP.Cf_New__ (info_,objid_,attr_cf_,'''',''DO'');
            END IF;
         END Add_Header_Note___;

         PROCEDURE Clear_Bulk_Update_Flag___
         IS
         BEGIN
            DELETE
              FROM ledger_item_ext_clt
             WHERE cf$_bulk_update_user = Fnd_Session_API.Get_Fnd_User;
                  
            DELETE
              FROM invoice_header_notes_ext_clt
             WHERE cf$_bulk_update_user = Fnd_Session_API.Get_Fnd_User;
         END Clear_Bulk_Update_Flag___;  
      BEGIN
         FOR rec_ IN bulk_update_notes_(:company_,:identity_) LOOP
          Dbms_Output.put_line(rec_.note_id);
          invoice_header_notes_rec_ := Get_Invoice_Header_Note___(rec_.company,rec_.invoice_id,rec_.note_id);
          FOR ledger_item_rec_ IN bulk_update_ledger_items_(rec_.company,rec_.identity,rec_.invoice_id) LOOP
             --clear_ledger_item_bulk_update_flag___(rec_.company,rec_.identity,rec_.invoice_id);
             DBMS_OUTPUT.put_line(rec_.invoice_id);      
             Add_Header_Note___(ledger_item_rec_.invoice_id,rec_.cf$_query_reason_db,invoice_header_notes_rec_);
          END LOOP;
         END LOOP;
         Clear_Bulk_Update_Flag___;
      END;';
   IF (Database_SYS.View_Exist('INVOICE_HEADER_NOTES_CFV') 
          AND Database_SYS.View_Exist('LEDGER_ITEM_CU_DET_QRY_CFV')
             AND Database_SYS.Method_Exist('INVOICE_HEADER_NOTES_API','New__')) THEN
      --@ApproveDynamicStatement('2021-02-16',EntPrageG);
      EXECUTE IMMEDIATE stmt_
      USING IN company_,
            IN identity_;
   ELSE
     Error_Sys.Appl_General(lu_name_,'Custom Objects are not published!');
   END IF;
END Bulk_Update_Invoice_Header_Notes__;

FUNCTION  Get_Update_Follow_Up_Date_Sql__(
   calender_id_    IN VARCHAR2,
   company_        IN VARCHAR2,
   invoice_id_     IN VARCHAR2,
   note_id_        IN NUMBER,
   note_status_id_ IN NUMBER) RETURN VARCHAR2
IS
   stmt_ VARCHAR2(32000);
BEGIN
  stmt_ := '
      DECLARE
         follow_up_date_ DATE;
         objkey_ VARCHAR2(50);
         company_ VARCHAR2(20);
         invoice_id_ VARCHAR2(20);
         note_id_ NUMBER;
         calender_id_       VARCHAR2(20);
         note_status_id_    NUMBER;         
         note_status_days_  VARCHAR2(20);
         query_reason_days_ VARCHAR2(20);
         
         FUNCTION Extract_Number___(text_ VARCHAR2) RETURN VARCHAR2
         IS
         BEGIN     
            RETURN REGEX_REPLACE(text_, ''[^[:digit:]]'', '''');
         END Extract_Number___;

         FUNCTION Get_Follow_Up_Time_Days___ (
            note_status_id_    IN NUMBER,
            note_status_days_  IN VARCHAR2) RETURN NUMBER
         IS
            working_days_ NUMBER;
         BEGIN
            working_days_ := NVL(Extract_Number___ (note_status_days_),0); 
            RETURN working_days_;
         END Get_Follow_Up_Time_Days___;

         FUNCTION Get_Follow_Up_Date___(
            calendar_id_       IN VARCHAR2,
            note_status_id_    IN NUMBER,      
            note_status_days_  IN VARCHAR2) RETURN DATE
         IS
            follow_up_days_ NUMBER;
            next_work_day_ DATE;
         BEGIN
            follow_up_days_ := Get_Follow_Up_Time_Days___(note_status_id_,note_status_days_);            
            SELECT work_day
              INTO next_work_day_
              FROM (SELECT work_day, rownum as counter
                      FROM work_time_counter
                     WHERE work_day > SYSDATE
                  ORDER BY counter) t
              WHERE t.counter = follow_up_days_;
         RETURN next_work_day_;
         EXCEPTION
           WHEN OTHERS THEN
             RETURN SYSDATE;
         END Get_Follow_Up_Date___;
       
         PROCEDURE Update_Follow_Up_Date___ (
           objkey_         VARCHAR2,
           follow_up_date_ DATE)
         IS
            invoice_header_notes_rec_ Invoice_Header_Notes_API.Public_Rec;
            attr_ VARCHAR2(32000);
            info_ VARCHAR2(4000);
            objid_      VARCHAR2(200);
            objversion_ VARCHAR2(200);
         BEGIN
            invoice_header_notes_rec_ := Invoice_Header_Notes_API.Get_By_Rowkey(objkey_);
            Client_SYS.Clear_Attr(attr_);
            Client_SYS.Add_To_Attr(''FOLLOW_UP_DATE'', follow_up_date_ , attr_);
            IF invoice_header_notes_rec_.note_id IS NOT NULL AND follow_up_date_ <> SYSDATE THEN
               objversion_ := TO_CHAR(invoice_header_notes_rec_.rowversion,''YYYYMMDDHH24MISS'');
               Invoice_Header_Notes_API.Modify__(info_, invoice_header_notes_rec_."rowid",objversion_ , attr_, ''DO'');
            END IF;
         END ;
    
         FUNCTION Get_Note_Status_Follow_Up_Days___ (
            company_        IN VARCHAR2,
            note_status_id_ IN NUMBER) RETURN VARCHAR2
         IS
            follow_up_days_ VARCHAR2(20);
         BEGIN
            SELECT cf$_follow_up_time
              INTO follow_up_days_
              FROM credit_note_status_cfv
             WHERE company = company_
               AND note_status_id = note_status_id_;
            RETURN follow_up_days_;
         EXCEPTION
            WHEN no_data_found THEN
               RETURN NULL;    
         END Get_Note_Status_Follow_Up_Days___;
      BEGIN
         calender_id_ := '''||calender_id_||''';
         note_status_id_ := '||note_status_id_||';
         company_ := '''||company_||''';
         invoice_id_ := '''||invoice_id_||''';
         note_id_:= '||note_id_||';

         objkey_:= Invoice_Header_Notes_API.Get_Objkey(company_, invoice_id_, note_id_);
         note_status_days_ := Get_Note_Status_Follow_Up_Days___ (company_ ,note_status_id_ );

         follow_up_date_ := Get_Follow_Up_Date___(calender_id_,note_status_id_,note_status_days_);  
         Update_Follow_Up_Date___(objkey_,follow_up_date_);         
      END;';
      RETURN stmt_;
END Get_Update_Follow_Up_Date_Sql__;

PROCEDURE Update_Follow_Up_Date__(
   calender_id_    IN VARCHAR2,
   company_        IN VARCHAR2,
   invoice_id_     IN VARCHAR2,
   note_id_        IN NUMBER,
   note_status_id_ IN NUMBER)
IS
   stmt_ VARCHAR2(32000);
BEGIN
  stmt_ := Get_Update_Follow_Up_Date_Sql__(calender_id_,company_,invoice_id_,note_id_,note_status_id_);
   IF (Database_SYS.View_Exist('CREDIT_NOTE_STATUS_CFV') 
          AND Database_SYS.View_Exist('QUERY_REASON_CLV')
             AND Database_SYS.View_Exist('INVOICE_HEADER_NOTES_CFV')) THEN
   --@ApproveDynamicStatement('2021-02-24',EntPrageG);
   EXECUTE IMMEDIATE stmt_;
   ELSE
      Error_Sys.Appl_General(lu_name_,'Custom Objects are not published!');
   END IF;
END Update_Follow_Up_Date__;

--C0392 EntPrageG (END)

FUNCTION Transf_Part_To_Inv_Part(
   target_key_ref_ IN VARCHAR2,
   service_name_   IN VARCHAR2)RETURN VARCHAR2 
IS
   part_no_ part_manu_part_no_tab.part_no%TYPE;
   source_key_ref_      VARCHAR2(32000);
   source_key_ref_list_ VARCHAR2(32000);

   CURSOR get_part_nos IS
      SELECT manufacturer_no, manu_part_no
        FROM part_manu_part_no_tab
       WHERE part_no = part_no_;
BEGIN
   part_no_ := Client_SYS.Get_Key_Reference_Value(target_key_ref_, 'PART_NO');
   FOR rec_ IN get_part_nos LOOP
      source_key_ref_ := 'MANU_PART_NO=' ||
      rec_.manu_part_no || '^MANUFACTURER_NO=' || rec_.manufacturer_no || '^PART_NO=' || part_no_ || '^';
      Obj_Connect_Lu_Transform_API.Add_To_Source_Key_Ref_List(source_key_ref_list_,source_key_ref_);
   END LOOP;
   RETURN source_key_ref_list_;
END Transf_Part_To_Inv_Part;

-- C0334
PROCEDURE Close_Non_Finance_User_Group     
IS 
  non_finance_user_group_ VARCHAR2(30) := 'NF'; 

  CURSOR check_valid_until_date IS
      SELECT * 
        FROM acc_period_ledger t
       WHERE date_until < SYSDATE
         AND period_status_db = 'O';  
BEGIN
  FOR rec_ IN check_valid_until_date LOOP 
     IF  (User_Group_Period_API.Check_Exist(rec_.company, 
                                            rec_.accounting_year, 
                                            rec_.accounting_period, 
                                            non_finance_user_group_, 
                                            rec_.ledger_id) = TRUE) THEN
        User_Group_Period_API.Close_Period(rec_.company,
                                           non_finance_user_group_,
                                           rec_.accounting_year,
                                           rec_.accounting_period,
                                           rec_.ledger_id);       

     END IF;
  END LOOP;
END Close_Non_Finance_User_Group;

--C0566 EntChamuA (START)
FUNCTION Transf_Mansup_Attach_To_PO(
   target_key_ref_ IN VARCHAR2,
   service_name_   IN VARCHAR2) RETURN VARCHAR2
IS
  order_no_            invoice_tab.po_ref_number%TYPE;
  source_key_ref_      VARCHAR2(32000);
  source_key_ref_list_ VARCHAR2(32000);

  CURSOR get_part_nos IS
    SELECT company, 
           invoice_id
      FROM invoice_tab
     WHERE rowtype LIKE '%ManSuppInvoice'
       AND po_ref_number = order_no_;

BEGIN
  order_no_ := Client_SYS.Get_Key_Reference_Value(target_key_ref_,'ORDER_NO');
  FOR rec_ IN get_part_nos LOOP
    source_key_ref_ := 'COMPANY=' || rec_.company || '^INVOICE_ID=' ||
                       rec_.invoice_id || '^';
    Obj_Connect_Lu_Transform_API.Add_To_Source_Key_Ref_List(source_key_ref_list_, source_key_ref_);
  END LOOP;

  RETURN source_key_ref_list_;

END Transf_Mansup_Attach_To_PO;
--C0566 EntChamuA (END)

-------------------- LU  NEW METHODS -------------------------------------
