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

-- C0436 EntPrageG (START)
PROCEDURE Get_Document_Keys_From_Key_Ref___(
   doc_class_ OUT VARCHAR2,
   doc_no_    OUT VARCHAR2,
   doc_sheet_ OUT VARCHAR,
   doc_rev_   OUT VARCHAR2,
   key_ref_    IN VARCHAR2)
IS
BEGIN
   doc_class_ := Client_SYS.Get_Key_Reference_Value(key_ref_, 'DOC_CLASS');
   doc_no_ := Client_SYS.Get_Key_Reference_Value(key_ref_, 'DOC_NO');
   doc_sheet_ := Client_SYS.Get_Key_Reference_Value(key_ref_, 'DOC_SHEET');
   doc_rev_ := Client_SYS.Get_Key_Reference_Value(key_ref_, 'DOC_REV');   
END Get_Document_Keys_From_Key_Ref___;

FUNCTION Get_Doc_Resp_Person___ (
   key_ref_ IN VARCHAR2) RETURN VARCHAR2
IS
   doc_class_  VARCHAR2(20);
   doc_no_     VARCHAR2(20);
   doc_sheet_  VARCHAR2(20);
   doc_rev_    VARCHAR2(20);  
   resp_per_ VARCHAR2(50);
BEGIN
   Get_Document_Keys_From_Key_Ref___(doc_class_,doc_no_,doc_sheet_,doc_rev_,key_ref_);
   resp_per_:= Doc_Issue_API.Get_Doc_Resp_Sign(doc_class_,doc_no_,doc_sheet_,doc_rev_);
RETURN resp_per_;
END Get_Doc_Resp_Person___;
-- C0436 EntPrageG (END)

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
      @ApproveDynamicStatement('2021-02-16',EntPrageG);
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
                     WHERE calendar_id = calendar_id_
                       AND work_day > SYSDATE
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
   @ApproveDynamicStatement('2021-02-24',EntPrageG);
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

--C0177 EntPrageG (START)   
PROCEDURE Create_Functional_Object__ (
   project_id_      IN VARCHAR2,
   sub_project_id_  IN VARCHAR2)
IS
   stmt_ VARCHAR2(32000);
BEGIN   
   stmt_ := '
   DECLARE
      project_id_ VARCHAR2(20);
      sub_project_id_ VARCHAR2(20);
      
      company_ VARCHAR2(20);
      object_id_              VARCHAR2(20);
      --sub_proj_inst_site_     VARCHAR2(20);
      sales_contract_no_      VARCHAR2(20);
      project_default_site_   VARCHAR2(20);
      installation_site_      VARCHAR2(10);
      warranty_period_        VARCHAR2(10);
      warranty_period_objkey_ VARCHAR2(50);

      hand_over_date_          DATE;
      sales_contract_site_rec_ Sales_Contract_Site_CLP.Public_Rec;
      object_count_ NUMBER := 0;
      eligible_parts_exist_ BOOLEAN := FALSE;  
      object_list_ VARCHAR2(32000);

      CURSOR get_activity_misc_parts IS
         SELECT part_no, part_desc, SUM(require_qty) quantity
           FROM (SELECT t.part_no,
                        Project_Misc_Procurement_API.
                           Get_Selected_Description(supply_option,site,t.part_no,matr_seq_no) part_desc,
                        require_qty
                   FROM project_misc_procurement t,
                        (SELECT part_no, contract, cf$_serviceable_Db
                           FROM sales_part_cfv t
                          WHERE t.cf$_serviceable_db = ''TRUE'') a
                  WHERE  t.site = a.contract
                    AND t.part_no = a.part_no
                    AND company = company_
                    AND t.activity_seq IN
                        (SELECT activity_seq
                           FROM activity1 t
                          WHERE t.sub_project_id = sub_project_id_
                            AND t.project_id = project_id_)
                    AND t.part_no IS NOT NULL)
       GROUP BY part_no, part_desc;

      PROCEDURE Add_To_Object_List___(
         object_id_ IN VARCHAR2)
      IS
      BEGIN
         object_list_ := object_list_ ||CHR(10)||CHR(13)||object_id_;
      END Add_To_Object_List___;

      FUNCTION Get_Object_Id___(
        project_id_     IN VARCHAR2,
        sub_project_id_ IN VARCHAR2) RETURN VARCHAR2 
      IS
        object_id_ VARCHAR2(50);
        rec_       Equipment_Object_api.Public_Rec;
      BEGIN
         SELECT cf$_object_id_db
           INTO object_id_
           FROM sub_project_cfv
          WHERE project_id = project_id_
            AND sub_project_id = sub_project_id_;
         rec_ := Equipment_Object_API.Get_By_Rowkey(object_id_);
         RETURN rec_.mch_code;
      EXCEPTION
         WHEN OTHERS THEN
            RETURN NULL;
      END Get_Object_Id___;

      FUNCTION Get_Sales_Contract_No___(
         project_id_ IN VARCHAR2,
         company_    IN VARCHAR2) RETURN VARCHAR2 
      IS
         sales_contract_no_ VARCHAR2(50);
      BEGIN
         SELECT cf$_sales_contract_no
           INTO sales_contract_no_
           FROM project_cfv
          WHERE project_id = project_id_
            AND company = company_;
         RETURN sales_contract_no_;
      EXCEPTION
         WHEN OTHERS THEN
           RETURN NULL;
      END Get_Sales_Contract_No___;

      FUNCTION Get_Installation_Site___(
         project_id_     IN VARCHAR2,
         sub_project_id_ IN VARCHAR2) RETURN VARCHAR2 
      IS
         installation_site_ VARCHAR2(50);
      BEGIN
         SELECT cf$_installation_site_no
           INTO installation_site_
           FROM sub_project_cfv
          WHERE project_id = project_id_
            AND sub_project_id = sub_project_id_;
         RETURN installation_site_;
      EXCEPTION
         WHEN OTHERS THEN
            RETURN NULL;
      END Get_Installation_Site___;

      FUNCTION Get_Sales_Contract_Site_Rec___(
         contract_no_ IN VARCHAR2,
         site_no_     IN VARCHAR2) RETURN Sales_Contract_Site_CLP.Public_Rec 
      IS
         objkey_ VARCHAR2(50);
         rec_    Sales_Contract_Site_CLP.Public_Rec;
      BEGIN
         SELECT a.objkey
           INTO objkey_
           FROM sales_contract_site_clv a, contract_revision b
          WHERE a.cf$_contract_no = b.contract_no
            AND a.cf$_rev_seq = b.rev_seq
            AND b.objstate = ''Active''
            AND a.cf$_contract_no = contract_no_
            AND a.cf$_site_no = site_no_;
         IF objkey_ IS NOT NULL THEN
           rec_ := Sales_Contract_Site_CLP.Get(objkey_);
         END IF;
         RETURN rec_;
      EXCEPTION
         WHEN OTHERS THEN
            RETURN NULL;
      END Get_Sales_Contract_Site_Rec___;

      FUNCTION Get_Service_warranty_Objkey___(
         warranty_period_ IN VARCHAR2) RETURN VARCHAR2 
      IS
         objkey_ VARCHAR2(50);
      BEGIN
         SELECT objkey
           INTO objkey_
           FROM warranty_clv
          WHERE cf$_warranty_period = warranty_period_;
         RETURN objkey_;
      EXCEPTION
         WHEN OTHERS THEN
            RETURN NULL;
      END Get_Service_warranty_Objkey___;

      FUNCTION Get_Default_Project_Site___(
         company_    IN VARCHAR2,
         project_id_ IN VARCHAR2) RETURN VARCHAR2 
      IS
         site_ VARCHAR2(20);
      BEGIN
         SELECT site
           INTO site_
           FROM project_site_ext
          WHERE company = company_
            AND project_id = project_id_
            AND project_site_type_db = ''DEFAULTSITE'';
         RETURN site_;
      EXCEPTION
         WHEN OTHERS THEN
            RETURN NULL;
      END Get_Default_Project_Site___;

      FUNCTION Get_Attr___(
         part_no_         IN VARCHAR2,
         part_desc_       IN VARCHAR2,
         project_id_      IN VARCHAR2,
         sub_project_id_  IN VARCHAR2,
         sup_mch_code_    IN VARCHAR2,
         production_date_ IN DATE,
         mode_            IN VARCHAR2 DEFAULT ''NEW'') RETURN VARCHAR2 
      IS
         attr_               VARCHAR2(32000);
         site_               VARCHAR2(20) := ''2013'';
         object_level_       VARCHAR2(100) := ''900_FUNCTIONAL_EQUIPMENT'';
         operational_status_ VARCHAR2(20) := ''IN_OPERATION'';
      BEGIN
         Client_SYS.Clear_Attr(attr_);
         IF mode_ = ''NEW'' THEN
            Client_SYS.Add_To_Attr(''PART_NO'', part_no_, attr_);
            Client_SYS.Add_To_Attr(''MCH_CODE'',part_no_ || project_id_ || sub_project_id_,attr_);
            Client_SYS.Add_To_Attr(''MCH_NAME'', part_desc_, attr_);
            Client_SYS.Add_To_Attr(''CONTRACT'', site_, attr_);
            Client_SYS.Add_To_Attr(''PRODUCTION_DATE'', production_date_, attr_);
            Client_SYS.Add_To_Attr(''SUP_CONTRACT'', site_, attr_); -- TO BE REMOVED
            Client_SYS.Add_To_Attr(''OBJ_LEVEL'', object_level_, attr_);
            Client_SYS.Add_To_Attr(''OPERATIONAL_STATUS_DB'',operational_status_,attr_);
            Client_SYS.Add_To_Attr(''SUP_MCH_CODE'', sup_mch_code_, attr_);
         ELSE
            Client_SYS.Add_To_Attr(''SUP_MCH_CODE'', sup_mch_code_, attr_);
         END IF;
         RETURN attr_;
      END Get_Attr___;

      FUNCTION Get_Cf_Attr___(
         project_id_       IN VARCHAR2,
         sub_project_id_   IN VARCHAR2,
         equipment_qty_    IN NUMBER,
         service_warranty_ IN VARCHAR2) RETURN VARCHAR2 
      IS
         attr_ VARCHAR2(32000);
      BEGIN
         Client_SYS.Clear_Attr(attr_);
         Client_SYS.Add_To_Attr(''CF$_EQUIPMENT_QUANTITY'', equipment_qty_, attr_);
         Client_SYS.Add_To_Attr(''CF$_SUB_PROJECT_ID'', sub_project_id_, attr_);
         Client_SYS.Add_To_Attr(''CF$_PROJ_ID'', project_id_, attr_);
         Client_SYS.Add_To_Attr(''CF$_SERVICE_WARRANTY_DB'', service_warranty_, attr_);
         RETURN attr_;
      END Get_Cf_Attr___;

      PROCEDURE Create_Funct_Equip_Obj___(
         part_no_          IN VARCHAR2,
         part_desc_        IN VARCHAR2,
         project_id_       IN VARCHAR2,
         sub_project_id_   IN VARCHAR2,
         sup_mch_code_     IN VARCHAR2,
         production_date_  IN DATE,
         equipment_qty_    IN NUMBER,
         service_warranty_ IN VARCHAR2) 
      IS
         info_       VARCHAR2(32000);
         objid_      VARCHAR2(50);
         objversion_ VARCHAR2(50);
         attr_       VARCHAR2(32000);
         attr_cf_    VARCHAR2(32000);
         site_       VARCHAR2(20) := ''2013'';
         current_sup_mch_code_ VARCHAR2(100);
         mch_code_ VARCHAR2(50);
         equip_func_obj_rec_ Equipment_Functional_API.Public_Rec;
      BEGIN
         mch_code_ := part_no_ || project_id_ || sub_project_id_;
         IF NOT Equipment_Functional_API.Exists(site_,mch_code_) THEN            
            attr_ := Get_Attr___(part_no_,
                                 part_desc_,
                                 project_id_,
                                 sub_project_id_,
                                 sup_mch_code_,
                                 production_date_);
            Equipment_Functional_API.New__(info_,objid_,objversion_,attr_,''DO'');            
            IF objid_ IS NOT NULL THEN             
               attr_cf_ := Get_Cf_Attr___(project_id_,sub_project_id_,equipment_qty_,service_warranty_);
               Equipment_Functional_CFP.Cf_New__(info_,objid_,attr_cf_,'''',''DO'');
            END IF;           
            Add_To_Object_List___(mch_code_);            
         ELSE
            current_sup_mch_code_:= Equipment_Functional_API.Get_Sup_Mch_Code(site_,mch_code_);
            IF sup_mch_code_ != current_sup_mch_code_ THEN
               attr_ := Get_Attr___(part_no_,
                                    part_desc_,
                                    project_id_,
                                    sub_project_id_,
                                    sup_mch_code_,
                                    production_date_,
                                    ''MODIFY'');
               equip_func_obj_rec_ := Equipment_Functional_API.Get(site_,mch_code_);
               Equipment_Functional_API.Modify__(info_,equip_func_obj_rec_."rowid",equip_func_obj_rec_.rowversion,attr_,''DO'');
               Add_To_Object_List___(mch_code_);               
            END IF;
         END IF;
         NULL;
      END Create_Funct_Equip_Obj___;

      PROCEDURE Validate_Prerequisites___(
         istallation_site_ IN VARCHAR2,
         contract_no_      IN VARCHAR2,
         hand_over_date_   IN DATE,
         warranty_period_  IN NUMBER)             
      IS
      BEGIN
         IF installation_site_ IS NULL THEN
            Error_SYS.Appl_General(''Custom'',''ERROR_NO_INSTALLATION_SITE: Sub project installation site is not set'');
         END IF;

         IF sales_contract_site_rec_.cf$_contract_no IS NULL THEN
            Error_SYS.Appl_General(''Custom'',
                                   ''ERROR_NO_INSTALLATION_SITE: Installation site :P1 is not found in installation sites of sales contract'',
                                   installation_site_);
         END IF;

         IF hand_over_date_ IS NULL THEN
            Error_SYS.Appl_General(''Custom'',
                                   ''ERROR_COMPLETE_DATE: Completion/Handover date of installation site of the sales contract is not set'');
         END IF;

         IF warranty_period_ IS NULL THEN
            Error_SYS.Appl_General(''Custom'',
                                   ''ERROR_WARRANTY_PERIOD: Warranty Period of installation site of the sales contract is not set'');
         END IF;   
      END Validate_Prerequisites___;
   BEGIN
      project_id_:= :project_id_;
      sub_project_id_ := :sub_project_id_;
      
      company_ := Project_API.Get_Company(project_id_);
      object_id_ := Get_Object_Id___(project_id_, sub_project_id_);

      IF object_id_ IS NULL THEN
         Error_SYS.Appl_General(''custom'',
                                ''ERROR_OBJ_ID: This operation is only possible for sub projects with Object ID'');
      END IF;
      --sub_proj_inst_site_ := Get_Installation_Site___(project_id_, sub_project_id_);    
      sales_contract_no_ := Get_Sales_Contract_No___(project_id_, company_);    
      project_default_site_ := Get_Default_Project_Site___(company_, project_id_);   
      installation_site_ := Get_Installation_Site___(project_id_,sub_project_id_);   
      sales_contract_site_rec_ := Get_Sales_Contract_Site_Rec___(sales_contract_no_, installation_site_);

      hand_over_date_  := sales_contract_site_rec_.cf$_delivered_on;
      warranty_period_ := sales_contract_site_rec_.cf$_warranty_period;

      Validate_Prerequisites___(installation_site_,sales_contract_site_rec_.cf$_contract_no,hand_over_date_,warranty_period_);

      warranty_period_objkey_ := Get_Service_warranty_Objkey___(warranty_period_);

      FOR rec_ IN get_activity_misc_parts LOOP
         IF rec_.quantity > 0 THEN 
            eligible_parts_exist_ := TRUE;
            Create_Funct_Equip_Obj___(rec_.part_no,
                                      rec_.part_desc,
                                      project_id_,
                                      sub_project_id_,
                                      object_id_,
                                      hand_over_date_,
                                      rec_.quantity,
                                      warranty_period_objkey_);
         END IF;
      END LOOP;
      IF object_list_ IS NOT NULL THEN
         Fnd_Stream_API.Create_Event_Action_Streams(Fnd_Session_API.Get_Fnd_User,
                                                    Fnd_Session_API.Get_Fnd_User,
                                                    ''Functional Objects Created'',''Following Functional Objects were created/modified for Sub Project ''
                                                    || project_id_ ||'' - ''||sub_project_id_ || CHR(13)||CHR(10)||object_list_,'''');
      ELSIF eligible_parts_exist_ THEN
         Fnd_Stream_API.Create_Event_Action_Streams(Fnd_Session_API.Get_Fnd_User,
                                                    Fnd_Session_API.Get_Fnd_User,
                                                    ''No Functional Objects Created'',''Functional Objects are already created for Sub Project '' || project_id_ ||'' - ''||sub_project_id_,'''');
      END IF;
   END;';
   
   IF (Database_SYS.View_Exist('WARRANTY_CLV') 
          AND Database_SYS.View_Exist('SALES_CONTRACT_SITE_CLV')
             AND Database_SYS.View_Exist('PROJECT_CFV')) THEN
      @ApproveDynamicStatement('2021-06-07',EntPrageG);
      EXECUTE IMMEDIATE stmt_
      USING IN project_id_,
            IN sub_project_id_;
   ELSE
     Error_Sys.Appl_General(lu_name_,'Custom Objects are not published!');
   END IF;
END Create_Functional_Object__;
--C0177 EntPrageG (END)

--C0438 EntPrageG (START)  
FUNCTION Get_Begin_Date__(
   year_    IN VARCHAR2,
   quarter_ IN VARCHAR2,
   month_   IN VARCHAR2,
   week_    IN VARCHAR2) RETURN DATE DETERMINISTIC
IS
   FUNCTION Get_Week_Start___(
      year_    IN VARCHAR2, 
      week_no_ IN VARCHAR2) RETURN DATE DETERMINISTIC
   IS
      week_start_date_ DATE;
   BEGIN
      SELECT MIN(dt)
        INTO week_start_date_
        FROM (SELECT dt, to_char(dt + 1, 'iw') week_no
                FROM (SELECT add_months(to_date('31/12/'||year_, 'dd/mm/yyyy'),-12) + ROWNUM dt
                        FROM all_objects
                       WHERE ROWNUM < 366))
       WHERE week_no = TO_NUMBER(week_no_);
      RETURN week_start_date_;
   END Get_Week_Start___;
BEGIN
   IF year_ IS NOT NULL OR year_ != '' THEN
      IF REGEXP_LIKE(year_, '^[[:digit:]]+$') THEN
         IF quarter_ IS NOT NULL OR quarter_ != '' THEN
            CASE quarter_
               WHEN '1' THEN
                  RETURN TO_DATE('01/01/2020', 'dd/mm/yyyy');
               WHEN '2' THEN
                  RETURN TO_DATE('01/04/2020', 'dd/mm/yyyy');
               WHEN '3' THEN
                  RETURN TO_DATE('01/07/2020', 'dd/mm/yyyy');
               WHEN '4' THEN
                  RETURN TO_DATE('01/10/2020', 'dd/mm/yyyy');
               ELSE
                  Error_SYS.Appl_General('Error','INVALID_FORMAT: Invalid Quater Value!');
            END CASE;
         ELSE
            IF month_ IS NOT NULL OR month_ != '' THEN
               IF REGEXP_LIKE(month_, '^[[:digit:]]+$') THEN
                  RETURN TO_DATE('01/' || month_ || '/' || year_, 'dd/mm/yyyy');
               ELSE
                  Error_SYS.Appl_General('Error','INVALID_FORMAT: Invalid Month Value!');
               END IF;
            ELSE
               IF week_ IS NOT NULL OR week_ != '' THEN
                  IF REGEXP_LIKE(week_, '^[[:digit:]]+$') THEN
                     RETURN Get_Week_Start___(year_,week_);
                  ELSE
                     Error_SYS.Appl_General('Error','INVALID_FORMAT: Invalid Week Value!');
                  END IF;
               END IF;
            END IF;
         END IF;
      RETURN TO_DATE('01/01/' || year_, 'dd/mm/yyyy');
   ELSE
      Error_SYS.Appl_General('Error','INVALID_FORMAT: Invalid Year Value!');
   END IF;
 ELSE
   RETURN TO_DATE('01/01/1900', 'dd/mm/yyyy');
 END IF;
END Get_Begin_Date__;

FUNCTION Get_End_Date__(
   year_    IN VARCHAR2,
   quarter_ IN VARCHAR2,
   month_   IN VARCHAR2,
   week_    IN VARCHAR2) RETURN DATE DETERMINISTIC 
IS
   FUNCTION Get_Week_End___(
      year_    IN VARCHAR2, 
      week_no_ IN VARCHAR2) RETURN DATE DETERMINISTIC
   IS
      week_end_date_ DATE;
   BEGIN
      SELECT MAX(dt)
        INTO week_end_date_
        FROM (SELECT dt, to_char(dt + 1, 'iw') week_no
                FROM (SELECT add_months(to_date('31/12/'||year_, 'dd/mm/yyyy'),-12) + ROWNUM dt
                        FROM all_objects
                       WHERE ROWNUM < 366))
       WHERE week_no = TO_NUMBER(week_no_);
      RETURN week_end_date_;
   END Get_Week_End___;
   
   FUNCTION End_Of_Date_Time___(
      date_ DATE) RETURN DATE
   IS
   BEGIN
       RETURN date_ + 86399/86400;
   END End_Of_Date_Time___; 
BEGIN
   IF year_ IS NOT NULL OR year_ != '' THEN
      IF REGEXP_LIKE(year_, '^[[:digit:]]+$') THEN
         IF quarter_ IS NOT NULL OR quarter_ != '' THEN
            CASE quarter_
               WHEN '1' THEN
                  RETURN End_Of_Date_Time___(add_months(last_day(trunc(to_date('01/01/2020',
                                                        'dd/mm/yyyy'),
                                                        'Q')),
                                                         2));
               WHEN '2' THEN
                  RETURN End_Of_Date_Time___(add_months(last_day(trunc(to_date('01/04/2020',
                                                        'dd/mm/yyyy'),
                                                        'Q')),
                                                        2));
               WHEN '3' THEN
                  RETURN End_Of_Date_Time___(add_months(last_day(trunc(to_date('01/07/2020',
                                                        'dd/mm/yyyy'),
                                                        'Q')),
                                                        2));
               WHEN '4' THEN
                  RETURN End_Of_Date_Time___(add_months(last_day(trunc(to_date('01/10/2020',
                                                       'dd/mm/yyyy'),
                                                       'Q')),
                                                       2));
               ELSE
                  Error_SYS.Appl_General('Error',
                                         'INVALID_FORMAT: Invalid Quater Value!');
            END CASE;
         ELSE
            IF month_ IS NOT NULL OR month_ != '' THEN
               IF REGEXP_LIKE(month_, '^[[:digit:]]+$') THEN
                  RETURN End_Of_Date_Time___(LAST_DAY(TO_DATE('01/' || month_ || '/' || year_,
                                             'dd/mm/yyyy')));
               ELSE
                  Error_SYS.Appl_General('Error',
                                         'INVALID_FORMAT: Invalid Month Value!');
               END IF;
            ELSE
               IF week_ IS NOT NULL OR month_ != '' THEN
                  IF REGEXP_LIKE(week_, '^[[:digit:]]+$') THEN
                     RETURN End_Of_Date_Time___(Get_Week_End___(year_,week_));
                  ELSE
                     Error_SYS.Appl_General('Error',
                                            'INVALID_FORMAT: Invalid Week Value!');
                  END IF;
               END IF;
          END IF;
        END IF;
           RETURN End_Of_Date_Time___(TO_DATE('31/12/' || year_, 'dd/mm/yyyy'));
      ELSE
         Error_SYS.Appl_General('Error',
                                'INVALID_FORMAT: Invalid Year Value!');
      END IF;
   ELSE
      RETURN End_Of_Date_Time___(TO_DATE('31/12/9999', 'dd/mm/yyyy'));
   END IF;
END Get_End_Date__;
--C0438 EntPrageG (END)

--C0628 EntPrageG (START)
PROCEDURE Copy_Circuit_Reference__(
   part_no_  IN VARCHAR2,
   part_rev_ IN VARCHAR2) 
IS
   stmt_ VARCHAR2(32000);
BEGIN
   stmt_ := 
      'DECLARE
         part_no_  VARCHAR2(20);
         part_rev_ VARCHAR2(20);

         sub_part_no_  VARCHAR2(20);
         sub_part_rev_ VARCHAR2(20);
         structure_id_ VARCHAR2(20);
         pos_          VARCHAR2(20);

         objkey_        VARCHAR2(50);
         source_objkey_ VARCHAR2(50);

         PROCEDURE Remove_Copy_Circuit_Ref_Flag___(
            objkey_ IN VARCHAR2) 
         IS
         BEGIN
            UPDATE eng_part_structure_cft
               SET cf$_copy_circuit_reference = NULL
             WHERE rowkey = objkey_;
         END Remove_Copy_Circuit_Ref_Flag___;

         PROCEDURE Copy_Circuit_Reference___(
            objkey_      IN VARCHAR2,
            circuit_ref_ IN VARCHAR2) 
         IS
            info_    VARCHAR2(4000);
            objid_   VARCHAR2(200);
            attr_cf_ VARCHAR2(4000);
            rec_     Eng_Part_Structure_API.Public_Rec;
         BEGIN
            rec_   := Eng_Part_Structure_API.Get_By_Rowkey(objkey_);
            objid_ := rec_."rowid";

            Client_SYS.Clear_Attr(attr_cf_);
            Client_SYS.Add_To_Attr(''CF$_CIRCUIT_REF'', circuit_ref_, attr_cf_);

            Eng_Part_Structure_CFP.Cf_New__(info_, objid_, attr_cf_, '''', ''DO'');
         END Copy_Circuit_Reference___;

         FUNCTION Get_Source_Eng_Part_Struc_Objkey___(
            part_no_      IN VARCHAR2,
            sub_part_no_  IN VARCHAR2,
            sub_part_rev_ IN VARCHAR2,
            structure_id_ IN VARCHAR2,
            pos_          IN VARCHAR2) RETURN VARCHAR2 
         IS
            objkey_ VARCHAR2(50);
         BEGIN
            SELECT objkey
              INTO objkey_
              FROM eng_part_structure_ext_cfv
             WHERE part_no = part_no_
               AND sub_part_no = sub_part_no_
               AND sub_part_rev = sub_part_rev_
               AND structure_id = structure_id_
               AND pos = pos_
               AND cf$_copy_circuit_reference_db = ''TRUE'';
         RETURN objkey_;
         EXCEPTION
            WHEN OTHERS THEN
              RETURN NULL;
         END Get_Source_Eng_Part_Struc_Objkey___;
      BEGIN
         part_no_ := :part_no_;      
         part_rev_ := :part_rev_;      

         FOR rec_ IN (SELECT *
                        FROM eng_part_structure_ext
                       WHERE part_no = part_no_
                         AND part_rev = part_rev_) LOOP
            sub_part_no_  := rec_.sub_part_no;
            sub_part_rev_ := rec_.sub_part_rev;
            structure_id_ := rec_.structure_id;
            pos_          := rec_.pos;

            objkey_ := Eng_Part_Structure_API.Get_Objkey(part_no_,
                                                         part_rev_,
                                                         sub_part_no_,
                                                         sub_part_rev_,
                                                         structure_id_,
                                                         pos_);

            source_objkey_ := Get_Source_Eng_Part_Struc_objkey___(part_no_,
                                                                  sub_part_no_,
                                                                  sub_part_rev_,
                                                                  structure_id_,
                                                                  pos_);

            IF source_objkey_ IS NOT NULL THEN
               IF Eng_Part_Structure_CFP.Get_Cf$_Copy_Circuit_Reference(source_objkey_) = ''TRUE'' THEN
                  Copy_Circuit_Reference___(objkey_,
                                            Eng_Part_Structure_CFP.Get_Cf$_Circuit_Ref(source_objkey_));
                  Remove_Copy_Circuit_Ref_Flag___(source_objkey_);
                END IF;
            END IF;
         END LOOP;
      END;';
   IF (Database_SYS.View_Exist('ENG_PART_STRUCTURE_EXT_CFV') AND
             Database_SYS.Package_Exist('ENG_PART_STRUCTURE_CFP')) THEN
      @ApproveDynamicStatement('2021-04-27',EntPragG);
      EXECUTE IMMEDIATE stmt_
        USING IN part_no_, IN part_rev_;
   ELSE
      Error_Sys.Appl_General(lu_name_, 'Custom Objects are not published!');
   END IF;   
END Copy_Circuit_Reference__;
--C0628 EntPrageG (END)

-- C0654 EntChamuA (START)
FUNCTION Check_Kitted_Reservation_Date(
   rev_start_date_  IN DATE,
   contract_        IN VARCHAR2) RETURN VARCHAR2
   
IS
   return_         VARCHAR2(6);
   i               NUMBER := 2;
   calender_id_    VARCHAR2(100);
   
   CURSOR get_info(count_row IN NUMBER, rev_start_date_ IN DATE, calender_id_ IN VARCHAR2) IS
      SELECT 'TRUE'
      FROM (SELECT work_day
         FROM (SELECT TRUNC(work_day) AS work_day, counter
            FROM (SELECT work_day, ROWNUM AS counter
               FROM work_time_counter
               WHERE calendar_id = calender_id_
               AND TRUNC(work_day) >= TRUNC(sysdate)
               AND ROWNUM <= 5
            ORDER BY work_day)
               WHERE counter = count_row)
               WHERE work_day = rev_start_date_);
   
BEGIN
   
   FOR l_counter IN 2 .. 5 LOOP
      
      calender_id_ := Site_API.Get_Manuf_Calendar_Id(contract_);
      
      OPEN get_info(i, rev_start_date_, calender_id_);
      FETCH get_info
         INTO return_;
      CLOSE get_info;
      
      IF (return_ IS NULL) THEN
         i := i + 1;
      END IF;
      
      IF (return_ = 'TRUE') THEN
         EXIT;
      END IF;
      
   END LOOP;
   
   RETURN return_;
END Check_Kitted_Reservation_Date;

PROCEDURE Reserve_Kitted_Kanban_Parts

IS
   info_ VARCHAR2(3200);
   attr_ VARCHAR2(3200);
   
   CURSOR get_kitted_parts IS 
      SELECT so.order_no AS order_no,
             so.release_no AS release_no,
             so.sequence_no AS sequence_no,
             soa.line_item_no AS line_item_no
      FROM shop_ord so, shop_material_alloc_uiv soa
      WHERE so.order_no = soa.order_no
      AND so.release_no = soa.release_no
      AND so.sequence_no = soa.sequence_no
      AND so.state IN ('Released', 'Reserved')
      AND soa.issue_type = 'Reserve'
      AND soa.consumption_item = 'Consumed'
      AND soa.qty_required - soa.qty_assigned <> '0'
      AND Check_Kitted_Reservation_Date(TRUNC(so.revised_start_date), so.contract) = 'TRUE';
   
   CURSOR get_kanban_parts IS
      SELECT so.order_no      AS order_no,
             so.release_no    AS release_no,
             so.sequence_no   AS sequence_no,
             soa.line_item_no AS line_item_no
      FROM shop_ord so, shop_material_alloc_uiv soa
      WHERE so.order_no = soa.order_no
      AND so.release_no = soa.release_no
      AND so.sequence_no = soa.sequence_no
      AND so.state IN ('Released', 'Reserved')
      AND soa.issue_type = 'Reserve And Backflush'
      AND soa.consumption_item = 'Consumed'
      AND soa.qty_required - soa.qty_assigned <> '0'
      AND Check_Kanban_Reservation_Date(TRUNC(so.revised_start_date), so.contract) = 'TRUE';
   
BEGIN
   
   FOR rec IN get_kitted_parts LOOP
      Shop_Material_Alloc_API.Reserve(info_, attr_, rec.order_no, rec.release_no, rec.sequence_no, rec.line_item_no);
      Client_SYS.Clear_ATTR(attr_);
   END LOOP;
   
   FOR rec_ IN get_kanban_parts LOOP
      Shop_Material_Alloc_API.Reserve(info_, attr_, rec_.order_no, rec_.release_no, rec_.sequence_no, rec_.line_item_no);
      Client_SYS.Clear_attr(attr_);
   END LOOP;
   
END Reserve_Kitted_Kanban_Parts;

FUNCTION Check_Kanban_Reservation_Date(
   rev_start_date_  IN DATE,
   contract_        IN VARCHAR2) RETURN VARCHAR2
IS
   return_         VARCHAR2(6);
   i               NUMBER := 2;
   calender_id_    VARCHAR2(100);
   
   CURSOR get_kanban_info(rev_start_date_ IN DATE, calender_id_ IN VARCHAR2) IS
      SELECT 'TRUE'
      FROM (SELECT work_day
         FROM (SELECT TRUNC(work_day) AS work_day, counter
            FROM (SELECT work_day, ROWNUM AS counter
               FROM work_time_counter
               WHERE calendar_id = calender_id_
               AND TRUNC(work_day) >=
               TRUNC(sysdate)
               AND ROWNUM <= 2
            ORDER BY work_day)
               WHERE counter = 2)
               WHERE work_day = rev_start_date_);
BEGIN   
   calender_id_ := Site_API.Get_Manuf_Calendar_Id(contract_);
   
   OPEN get_kanban_info(rev_start_date_, calender_id_);
   FETCH get_kanban_info
      INTO return_;
   CLOSE get_kanban_info;
   RETURN return_;
END Check_Kanban_Reservation_Date; 
-- C0654 EntChamuA (END)

--C0446 EntChamuA (START)
PROCEDURE Create_Equipment_Object__(
   order_no_ IN VARCHAR2) 
IS
   temps_      NUMBER;
   seriliazed_ NUMBER;
   object_id_  VARCHAR2(3200);
   
   -- To get customer order lines 
   CURSOR get_co_line IS
      SELECT line_no,
             rel_no,
             line_item_no,
             catalog_no,
             contract,
             cust_warranty_id,
             real_ship_date,
             catalog_desc,
             cf$_object_id,
             buy_qty_due,
             objid
        FROM customer_order_line_cfv a
       WHERE order_no = order_no_
         AND state IN ('Delivered', 'Invoiced/Closed', 'Partially Delivered');
   
   CURSOR check_sales_part(catalog_ IN VARCHAR2) IS
      SELECT 1
        FROM sales_part_cfv
       WHERE catalog_no = catalog_
         AND contract = '2012'
         AND cf$_serviceable_db = 'TRUE';
   
   --Check serialised
   CURSOR check_serialized(catalog_ IN VARCHAR2) IS
      SELECT 1 
        FROM part_serial_catalog 
       WHERE part_no = catalog_;
BEGIN
   
   FOR rec_ IN get_co_line LOOP
      -- To check sales part 
      OPEN check_sales_part(rec_.catalog_no);
      FETCH check_sales_part INTO temps_;
      CLOSE check_sales_part;
      
      object_id_ := SUBSTR(rec_.CF$_OBJECT_ID, INSTR(rec_.CF$_OBJECT_ID, '^') + 1, length(rec_.CF$_OBJECT_ID));
      
      IF (object_id_ IS NOT NULL) THEN
         --Create objects only if site 2012 and serviceable
         IF (temps_ = 1) THEN
            OPEN check_serialized(rec_.catalog_no);
            FETCH check_serialized INTO seriliazed_;
            IF (check_serialized%FOUND) THEN
               
               Create_Serial_Object__(rec_.catalog_no,
                  order_no_,
                  rec_.line_no,
                  rec_.line_item_no,
                  rec_.rel_no,
                  rec_.cust_warranty_id,
                  object_id_,
                  rec_.objid,
                  rec_.real_ship_date);
               temps_ := 0;
            ELSE
               Create_Functional_Object_(rec_.catalog_no,
                  order_no_,
                  rec_.line_no,
                  rec_.rel_no,
                  TRUNC(rec_.real_ship_date),
                  rec_.cust_warranty_id,
                  object_id_,
                  rec_.catalog_desc,
                  rec_.contract,
                  rec_.buy_qty_due,
                  rec_.objid);
               temps_ := 0;
            END IF;
            CLOSE check_serialized;
         END IF;
      END IF;
   END LOOP;
END Create_Equipment_Object__;

PROCEDURE Create_Functional_Object_(
   catalog_no_     IN VARCHAR2,
   order_no_       IN VARCHAR2,
   line_no_        IN VARCHAR2,
   rel_no_         IN VARCHAR2,
   real_ship_date_ IN DATE,
   warranty_id_    IN VARCHAR2,
   object_id_      IN VARCHAR2,
   catalog_desc_   IN VARCHAR2,
   contract_       IN VARCHAR2,
   buy_qty_due_    IN NUMBER,
   col_objid_      IN VARCHAR2) 
IS
   status_                VARCHAR2(100);
   type_                  VARCHAR2(100);
   unit_                  VARCHAR2(100);
   values_                VARCHAR2(10);
   value_                 NUMBER;
   lot_no_                VARCHAR2(20);
   func_obj_              VARCHAR2(3200);
   info_                  VARCHAR2(3200);
   objid_                 VARCHAR2(3200);
   objversion_            VARCHAR2(3200);
   attr_                  VARCHAR2(3200);
   warr_objkey_           VARCHAR2(3200);
   contract_2_            VARCHAR2(3200) := '2013';
   current_sup_mch_code_  VARCHAR2(3200);
   attr_2_                VARCHAR2(3200);
   attr_cf_               VARCHAR2(3200);
   
   --to get lot number and qty 
   CURSOR get_lot_batch_dets(order_no_   IN VARCHAR2,
                             line_no_    IN VARCHAR2,
                             rel_no_     IN VARCHAR2,
                             catalog_no_ IN VARCHAR2,
                             contract_   IN VARCHAR2) IS
      SELECT lot_batch_no
        FROM lot_batch_history a
       WHERE order_ref1 = order_no_
         AND order_ref2 = line_no_
         AND order_ref3 = rel_no_
         AND contract = contract_
         AND part_no = catalog_no_
         AND order_type_db = 'CUST ORDER'
         AND transaction_desc LIKE 'Delivered on customer order %';
   
   --get warranty type 
   CURSOR get_warranty_type(warranty_id_ IN VARCHAR2) IS
      SELECT warranty_type_id
        FROM cust_warranty_type
       WHERE warranty_id = warranty_id_;
   
   -- get warranty details 
   CURSOR get_warranty_info(warranty_id_ IN VARCHAR2,
      type_id_     IN VARCHAR2) IS
         SELECT Warranty_Condition_API.Get_Time_Unit(condition_id), MAX_VALUE
           FROM cust_warranty_condition
          WHERE warranty_id = warranty_id_
            AND warranty_type_id = type_id_;
   
   --get objkey of warranty 
   CURSOR get_objkey(values_ IN VARCHAR2) IS
      SELECT OBJKEY FROM warranty_clv WHERE CF$_NAME = values_;
   
   --get objid and objversion 
   CURSOR get_equipment_object_dets(contract_ IN VARCHAR2, mch_code_ IN VARCHAR2) IS
      SELECT objid, objversion
        FROM equipment_object
       WHERE contract = contract_
         AND mch_code = mch_code_;
   
BEGIN
   IF (object_id_ IS NOT NULL) THEN
      
      status_ := Cust_Warranty_API.Get_Objstate(warranty_id_);
      OPEN get_lot_batch_dets(order_no_, line_no_, rel_no_, catalog_no_, contract_);
      FETCH get_lot_batch_dets INTO lot_no_;
      CLOSE get_lot_batch_dets;
      
      OPEN get_warranty_type(warranty_id_);
      FETCH get_warranty_type INTO type_;
      CLOSE get_warranty_type;
      
      OPEN get_warranty_info(warranty_id_, type_);
      FETCH get_warranty_info INTO unit_, value_;
      CLOSE get_warranty_info;
      
      IF (unit_ = 'Year') THEN
         value_ := value_ * 12;
      END IF;
      
      values_   := value_ || 'M';
      func_obj_ := catalog_no_ || '_' || order_no_ || '_' || rel_no_;
      
      Client_SYS.Add_To_Attr('MCH_CODE', func_obj_, attr_);
      Client_SYS.Add_To_Attr('MCH_NAME', catalog_desc_, attr_);
      Client_SYS.Add_To_Attr('CONTRACT', '2013', attr_);
      Client_SYS.Add_To_Attr('OBJ_LEVEL', '900_FUNCTIONAL_EQUIPMENT', attr_);
      Client_SYS.Add_To_Attr('PART_NO', catalog_no_, attr_);
      Client_SYS.Add_To_Attr('PRODUCTION_DATE', real_ship_date_, attr_);
      Client_SYS.Add_To_Attr('SUP_MCH_CODE', object_id_, attr_);
      Client_SYS.Add_To_Attr('SUP_CONTRACT', '2013', attr_);
      
      IF NOT Equipment_Functional_API.Exists(contract_2_, func_obj_) THEN            
         
         Equipment_Functional_API.New__(info_, objid_, objversion_, attr_, 'DO');
         
         Client_Sys.Clear_Attr(attr_);
         
         IF (values_ IS NOT NULL) THEN
            OPEN get_objkey(values_);
            FETCH get_objkey INTO warr_objkey_;
            CLOSE get_objkey;
         END IF;
         
         Client_SYS.Add_To_Attr('CF$_LOT_BATCH_NO', lot_no_, attr_);
         Client_SYS.Add_To_Attr('CF$_EQUIPMENT_QUANTITY', buy_qty_due_, attr_);
         Client_SYS.Add_To_Attr('CF$_SERVICE_WARRANTY', warr_objkey_, attr_);
         Equipment_Functional_CFP.Cf_Modify__(info_, objid_, attr_, ' ', 'DO');
         
         Client_SYS.Add_To_Attr('CF$_OBJECT_CREATED', func_obj_, attr_cf_);
         Customer_Order_Line_CFP.Cf_Modify__(info_, col_objid_, attr_cf_, ' ', 'DO');
      ELSE
         current_sup_mch_code_:= Equipment_Functional_API.Get_Sup_Mch_Code(contract_2_, func_obj_);
         
         IF object_id_ != current_sup_mch_code_ THEN
            OPEN get_equipment_object_dets (contract_2_, func_obj_);
            FETCH get_equipment_object_dets INTO objid_, objversion_;
            CLOSE get_equipment_object_dets;
            
            Client_SYS.Add_To_Attr('SUP_MCH_CODE', object_id_, attr_2_);
            Equipment_Functional_API.Modify__(info_, objid_, objversion_, attr_2_, 'DO');
         END IF;
      END IF;
   END IF;
END Create_Functional_Object_;

PROCEDURE Create_Serial_Object__(
   catalog_no_     IN VARCHAR2,
   order_no_       IN VARCHAR2,
   line_no_        IN VARCHAR2,
   line_item_no_   IN VARCHAR2,
   rel_no_         IN VARCHAR2,
   warranty_id_    IN VARCHAR2,
   object_id_      IN VARCHAR2,
   col_objid_      IN VARCHAR2,
   real_ship_date_ IN DATE) 
IS  
   max_value_    NUMBER;
   unit_         VARCHAR2(10);
   sstep1_       VARCHAR2(100);
   sstep2_       VARCHAR2(100);
   sstep3_       VARCHAR2(100);
   sstep4_       VARCHAR2(50);
   mch_code_     VARCHAR2(2000):= NULL;
   site_         VARCHAR2(2000);
   info_         VARCHAR2(3200);
   objid_        VARCHAR2(3200);
   objversion_   VARCHAR2(3200);
   attr_         VARCHAR2(3200);
   contract_     VARCHAR2(50) := '2013';
   warr_objkey_  VARCHAR2(3200);
   values_       VARCHAR2(10);
   sup_mch_code_ VARCHAR2(2000);
   obj_created_  VARCHAR2(2000);
   concat_obj_   VARCHAR2(3200):= NULL;
   
   --To get serial objects qty per CO line
   CURSOR get_serial_objects_col(catalog_   IN VARCHAR2,
                                 order_no_ IN VARCHAR2,
                                 line_no_  IN VARCHAR2,
                                 item_no_  IN NUMBER,
                                 rel_no_   IN NUMBER) IS
      SELECT transaction_date, serial_no, sequence_no
        FROM part_serial_history_tab
       WHERE part_no = catalog_
         AND order_no = order_no_
         AND line_no = line_no_
         AND line_item_no = item_no_
         AND release_no = rel_no_
         AND order_type = 'CUST ORDER'
         AND transaction_description LIKE '%Delivered on customer order%';
   
   --To get warranty details for serial object
   CURSOR get_serial_warranty_dets(catalog_   IN VARCHAR2,
                                   warr_id_   IN NUMBER,
                                   serial_no_ IN VARCHAR2) IS
      SELECT b.max_value,
             Warranty_Condition_API.Get_Time_Unit(a.condition_id) AS Time_Unit
        FROM serial_warranty_dates a, cust_warranty_temp_cond b
       WHERE a.warranty_type_id = b.template_id
         AND a.condition_id = b.condition_id
         AND a.warranty_id = warr_id_
         AND a.part_no = catalog_
         AND a.serial_no = serial_no_;
   
   --to modify production date of serial objects
   CURSOR modify_serial_obj_date(mch_code_  IN VARCHAR,
                                 serial_no_ IN VARCHAR) IS
         SELECT objid, objversion
           FROM equipment_serial a
          WHERE a.serial_no = serial_no_
            AND a.mch_code = mch_code_;
   
   --get objkey of warranty 
   CURSOR get_objkey(values_ IN VARCHAR2) IS
      SELECT objkey 
      FROM warranty_clv 
      WHERE cf$_name = values_;
   
   CURSOR get_serial_object(order_no_ IN VARCHAR2, catalog_no_ IN VARCHAR2) IS
      SELECT mch_code, objid, objversion
        FROM equipment_serial_cfv 
       WHERE cf$_customer_order_no = order_no_
         AND part_no = catalog_no_;

   CURSOR get_co_line_obj(order_no_ IN VARCHAR2, catalog_no_ IN VARCHAR2) IS
      SELECT cf$_object_created
        FROM customer_order_line_cfv
       WHERE order_no = order_no_
         AND catalog_no = catalog_no_;
   
BEGIN
   IF (object_id_ IS NOT NULL) THEN
      --create serial object
      FOR obj IN get_serial_objects_col(catalog_no_, order_no_, line_no_,  line_item_no_, rel_no_) LOOP
         
         --For each object get warranty details
         OPEN get_serial_warranty_dets(catalog_no_, warranty_id_, obj.serial_no);
         FETCH get_serial_warranty_dets INTO max_value_, unit_;
         CLOSE get_serial_warranty_dets;
         
         IF (unit_ = 'Year') THEN
            max_value_ := max_value_ * 12;
         END IF;
         
         values_ := max_value_ || 'M';
         
         IF (values_ IS NOT NULL) THEN
            OPEN get_objkey(values_);
            FETCH get_objkey INTO warr_objkey_;
            CLOSE get_objkey;
         END IF;
         
         sstep1_ := Equipment_Serial_API.Check_Serial_Exist(catalog_no_,obj.serial_no);
         
         sstep2_ := Maintenance_Site_Utility_API.Is_User_Allowed_Site(contract_);
         
         sstep3_ := Part_Serial_Catalog_API.Get_Objstate(catalog_no_,obj.serial_no);
         
         sstep4_ := Part_Serial_Catalog_API.Delivered_To_Internal_Customer(catalog_no_,obj.serial_no);

         OPEN get_co_line_obj(order_no_, catalog_no_);
         FETCH get_co_line_obj INTO obj_created_;
         IF(obj_created_ IS null)THEN
            --CREATE NEW SERIAL OBJECTS
            Equipment_Serial_API.Create_Maintenance_Aware(catalog_no_, obj.serial_no, contract_, NULL, 'FALSE');
            Equipment_Serial_API.Get_Obj_Info_By_Part(site_, mch_code_, catalog_no_, obj.serial_no);
            Equipment_Object_API.Move_From_Invent_To_Facility(contract_, object_id_, catalog_no_, obj.serial_no, mch_code_);
            
            OPEN modify_serial_obj_date(mch_code_, obj.serial_no);
            FETCH modify_serial_obj_date INTO objid_, objversion_;
            CLOSE modify_serial_obj_date;
            
            Client_Sys.Add_To_Attr('PRODUCTION_DATE', real_ship_date_, attr_);
            Equipment_Serial_API.Modify__(info_,objid_,objversion_, attr_,'DO');
            
            Client_Sys.Clear_Attr(attr_);
            
            Client_Sys.Add_To_Attr('CF$_SERVICE_WARRANTY', warr_objkey_, attr_);
            Client_Sys.Add_To_Attr('CF$_CUSTOMER_ORDER_NO', order_no_, attr_);
            Equipment_Serial_CFP.Cf_Modify__(info_, objid_, attr_, ' ', 'DO');
            
            concat_obj_ := mch_code_||';'||concat_obj_;
         ELSE
            FOR rec_modify_ IN get_serial_object(order_no_, catalog_no_)LOOP
               sup_mch_code_:= Equipment_Serial_API.Get_Sup_Mch_Code(contract_, rec_modify_.mch_code);
               IF(sup_mch_code_ != object_id_ )THEN  
                  Client_SYS.Clear_Attr(attr_);
                  Client_Sys.Add_To_Attr('SUP_MCH_CODE', object_id_, attr_);
                  Equipment_Serial_API.Modify__(info_, rec_modify_.objid, rec_modify_.objversion, attr_, 'DO');
               END IF;
            END LOOP;
         END IF;
         CLOSE get_co_line_obj;
      END LOOP;
      IF(obj_created_ IS null) THEN
         Client_Sys.Clear_Attr(attr_);
         Client_Sys.Add_To_Attr('CF$_OBJECT_CREATED', concat_obj_, attr_);
         Customer_Order_Line_CFP.Cf_Modify__(info_, col_objid_, attr_, ' ', 'DO');
      END IF;
   END IF; 
END Create_Serial_Object__;
--C0446 EntChamuA (END)

-- C0401 EntPragG (START)
PROCEDURE Generate_CWU_Report_Multilevel(
   part_no_       IN VARCHAR2,
   contract_      IN VARCHAR2,
   eng_chg_level_ IN VARCHAR2)
IS
   hierachy_ VARCHAR2(32000);      
   phase_in_date_ DATE;
   phase_out_date_ DATE;
   order_ NUMBER := 0;
   
   FUNCTION Get_Attr___ (
      level_               IN VARCHAR2,
      child_part_no_       IN VARCHAR2,
      bom_type_            IN VARCHAR2,
      child_eng_chg_level_ IN VARCHAR2,
      alternative_no_      IN VARCHAR2,
      child_contract_      IN VARCHAR2,
      qty_per_assembly_    IN NUMBER) RETURN VARCHAR2
   IS
      attr_ VARCHAR2(32000);
   BEGIN
      order_ := order_ + 1;
      Client_SYS.Clear_Attr(attr_);
      Client_SYS.Add_To_Attr('CF$_LEVEL', level_, attr_);
      Client_SYS.Add_To_Attr('CF$_PART_NO', child_part_no_, attr_);
      Client_SYS.Add_To_Attr('CF$_BOM_TYPE', bom_type_, attr_);
      Client_SYS.Add_To_Attr('CF$_ENG_CHG_LEVEL', child_eng_chg_level_, attr_);
      Client_SYS.Add_To_Attr('CF$_ALTERNATIVE_NO', alternative_no_, attr_);
      Client_SYS.Add_To_Attr('CF$_CONTRACT', child_contract_, attr_);
      Client_SYS.Add_To_Attr('CF$_QTY_PER_ASSEMBLY', qty_per_assembly_, attr_);
      Client_SYS.Add_To_Attr('CF$_REPORT_PART_NO', part_no_, attr_);
      Client_SYS.Add_To_Attr('CF$_REPORT_ENG_CHG_LEVEL', eng_chg_level_, attr_);
      Client_SYS.Add_To_Attr('CF$_REPORT_USER', Fnd_Session_API.Get_Fnd_User, attr_);      
      Client_SYS.Add_To_Attr('CF$_REPORT_CONTRACT', contract_, attr_);
      Client_SYS.Add_To_Attr('CF$_ORDER', order_, attr_);
      RETURN attr_;
   END Get_Attr___;
   
   PROCEDURE Clean_Up_Report_Entries___(
      part_no_       IN VARCHAR2,      
      contract_      IN VARCHAR2,
      eng_chg_level_ IN VARCHAR2)
   IS
      stmt_ VARCHAR2(1000);
   BEGIN
      stmt_ := 
         'BEGIN
            DELETE
              FROM cwu_report_multilevel_clt
             WHERE cf$_report_part_no = :part_no_
               AND cf$_report_eng_chg_level = :eng_chg_level_
               AND cf$_report_contract = :contract_
               AND cf$_report_user = Fnd_Session_API.Get_Fnd_User;
         END;';
      @ApproveDynamicStatement(2021-07-12,EntPrageG)     
      EXECUTE IMMEDIATE stmt_
         USING IN part_no_, IN eng_chg_level_, IN contract_;
   END Clean_Up_Report_Entries___;
   
   PROCEDURE Create_Report_Entry___(
      level_            IN VARCHAR2,
      part_no_          IN VARCHAR2,
      eng_chg_level_    IN VARCHAR2,
      contract_         IN VARCHAR2,      
      bom_type_         IN VARCHAR2 DEFAULT NULL,
      alternative_no_   IN VARCHAR2 DEFAULT NULL,
      qty_per_assembly_ IN NUMBER DEFAULT NULL)
   IS
      attr_ VARCHAR2(32000);
      info_ VARCHAR2(32000);
      objid_ VARCHAR2(50);
      objversion_ VARCHAR2(50);
      stmt_ VARCHAR2(2000);
   BEGIN
      stmt_ := 
         'BEGIN                
             Cwu_Report_Multilevel_CLP.New__(:info_,:objid_,:objversion_,:attr_,''DO'');
          END;';
      attr_ := Get_Attr___(level_,part_no_,bom_type_,eng_chg_level_,alternative_no_,contract_,qty_per_assembly_);
      @ApproveDynamicStatement(2021-07-12,EntPragG)
      EXECUTE IMMEDIATE stmt_
         USING OUT info_, OUT objid_, OUT objversion_, IN OUT attr_;
   END Create_Report_Entry___;
   
   PROCEDURE Build_Part_Hierachy___(
      hierachy_       IN OUT VARCHAR2,
      part_no_            IN VARCHAR2,
      contract_           IN VARCHAR2,
      level_              IN NUMBER,
      phase_in_date_      IN DATE,
      phase_out_date_     IN DATE)
   IS
      next_level_ NUMBER;
      CURSOR get_component_part_ IS
         SELECT part_no,
                bom_Type,
                eng_chg_level,
                alternative_no,
                contract,
                qty_per_assembly,
                eff_phase_in_date,
                eff_phase_out_date
           FROM manuf_structure t
          WHERE component_part = part_no_
            AND contract = contract_
            AND bom_type_db IN ('M', 'T')
            AND eng_chg_level IN
                              (SELECT eng_chg_level
                                 FROM manuf_structure
                                WHERE component_contract = t.component_contract
                                  AND component_part = t.component_part
                                  AND part_no = t.part_No
                                  AND bom_type_db = t.bom_type_db
                                  AND eff_phase_out_date IS NULL)
            AND (
                 ((eff_phase_out_date IS NULL) AND (phase_out_date_ IS NULL)) OR 
                 ((phase_out_date_ IS NULL) AND (eff_phase_out_date >= phase_in_date_ )) OR
                 ((eff_phase_out_date IS NULL) AND ( phase_in_date_ >= eff_phase_in_date)) OR
                 ((eff_phase_out_date IS NULL) AND (phase_out_date_ >= eff_phase_in_date)) OR
                 (eff_phase_in_date BETWEEN phase_in_date_ AND phase_out_date_ ) OR
                 (eff_phase_out_date BETWEEN phase_in_date_ AND phase_out_date_ ) OR
                 (phase_in_date_ BETWEEN eff_phase_in_date AND eff_phase_out_date) OR
                 (phase_out_date_ BETWEEN eff_phase_in_date AND eff_phase_out_date)
                );
   BEGIN
      FOR rec_ IN get_component_part_  LOOP          
        --hierachy_ := hierachy_  ||','|| LPAD(level_,(level_),'.') || '<<#>>' ||rec_. part_no || '<<>>' || rec_. bom_Type || '<<>>' || rec_. eng_chg_level || '<<>>' || rec_. alternative_no || '<<>>' || contract_ || '<<#>>' ||rec_.qty_per_assembly;
        Create_Report_Entry___(LPAD(level_,(level_),'.'),rec_.part_no,rec_.eng_chg_level,contract_,rec_.bom_Type,rec_.alternative_no,rec_.qty_per_assembly);
        next_level_ := level_+1;
        Build_Part_Hierachy___(hierachy_,rec_.part_no, contract_,next_level_,rec_.eff_phase_in_date,rec_.eff_phase_out_date);                             
      END LOOP; 
   END Build_Part_Hierachy___;

   FUNCTION Get_Phase_In_Date___(
      part_no_       IN VARCHAR,
      eng_chg_level_ IN VARCHAR2) RETURN DATE DETERMINISTIC
   IS
      phase_in_date_ DATE;
   BEGIN
      SELECT eff_phase_in_date
        INTO phase_in_date_
        FROM part_revision
       WHERE part_no = part_no_
         AND eng_chg_level = eng_chg_level_;
      RETURN phase_in_date_;
   EXCEPTION
      WHEN OTHERS THEN
         RETURN NULL;
   END Get_Phase_In_Date___;

   FUNCTION Get_Phase_Out_Date___(
      part_no_       IN VARCHAR,
      eng_chg_level_ IN VARCHAR2) RETURN DATE DETERMINISTIC
   IS
      phase_in_date_ DATE;
   BEGIN
      SELECT eff_phase_out_date
        INTO phase_in_date_
        FROM part_revision
       WHERE part_no = part_no_
         AND eng_chg_level = eng_chg_level_;
      RETURN phase_in_date_;
   EXCEPTION
      WHEN OTHERS THEN
         RETURN NULL;
   END Get_Phase_Out_Date___;      
BEGIN
   phase_in_date_:= Get_Phase_In_Date___(part_no_,eng_chg_level_);
   phase_out_date_ := Get_Phase_Out_Date___(part_no_,part_no_);
   --hierachy_ := '1' || '<<#>>' || part_no_ || '<<>>' || '' || '<<>>' || eng_chg_level_ || '<<>>' || '' || '<<>>' || contract_;   
   Clean_Up_Report_Entries___(part_no_,contract_,eng_chg_level_);
   Create_Report_Entry___('1',part_no_,eng_chg_level_,contract_);
   Build_Part_Hierachy___(hierachy_,part_no_,contract_,2,phase_in_date_,phase_out_date_);
END Generate_CWU_Report_Multilevel; 

FUNCTION Get_Part_Hierachy__(
   part_no_       IN VARCHAR2,
   contract_      IN VARCHAR2,
   eng_chg_level_ IN VARCHAR2) RETURN VARCHAR2 DETERMINISTIC
IS
   hierachy_ VARCHAR2(32000);      
   phase_in_date_ DATE;
   phase_out_date_ DATE;

   PROCEDURE Build_Part_Hierachy___(
      hierachy_       IN OUT VARCHAR2,
      part_no_            IN VARCHAR2,
      contract_           IN VARCHAR,
      level_              IN NUMBER,
      phase_in_date_      IN DATE,
      phase_out_date_     IN DATE)
   IS
      next_level_ NUMBER;
      CURSOR get_component_part_ IS
         SELECT part_no,
                bom_Type,
                eng_chg_level,
                alternative_no,
                contract,
                qty_per_assembly,
                eff_phase_in_date,
                eff_phase_out_date
           FROM manuf_structure t
          WHERE component_part = part_no_
            AND contract = contract_
            AND bom_type_db IN ('M', 'T')
            AND eng_chg_level IN
                              (SELECT eng_chg_level
                                 FROM manuf_structure
                                WHERE component_contract = t.component_contract
                                  AND component_part = t.component_part
                                  AND part_no = t.part_No
                                  AND bom_type_db = t.bom_type_db
                                  AND eff_phase_out_date IS NULL)
            AND (
                 ((eff_phase_out_date IS NULL) AND (phase_out_date_ IS NULL)) OR 
                 ((phase_out_date_ IS NULL) AND (eff_phase_out_date >= phase_in_date_ )) OR
                 ((eff_phase_out_date IS NULL) AND ( phase_in_date_ >= eff_phase_in_date)) OR
                 ((eff_phase_out_date IS NULL) AND (phase_out_date_ >= eff_phase_in_date)) OR
                 (eff_phase_in_date BETWEEN phase_in_date_ AND phase_out_date_ ) OR
                 (eff_phase_out_date BETWEEN phase_in_date_ AND phase_out_date_ ) OR
                 (phase_in_date_ BETWEEN eff_phase_in_date AND eff_phase_out_date) OR
                 (phase_out_date_ BETWEEN eff_phase_in_date AND eff_phase_out_date)
                );
   BEGIN
      FOR rec_ IN get_component_part_  LOOP          
        hierachy_ := hierachy_  ||','|| LPAD(level_,(level_),'.') || '<<#>>' ||rec_. part_no || '<<>>' || rec_. bom_Type || '<<>>' || rec_. eng_chg_level || '<<>>' || rec_. alternative_no || '<<>>' || contract_ || '<<#>>' ||rec_.qty_per_assembly;
        next_level_ := level_+1;
        Build_Part_Hierachy___(hierachy_,rec_.part_no, contract_,next_level_,rec_.eff_phase_in_date,rec_.eff_phase_out_date);                             
      END LOOP; 
   END Build_Part_Hierachy___;

   FUNCTION Get_Phase_In_Date___(
      part_no_       IN VARCHAR,
      eng_chg_level_ IN VARCHAR2) RETURN DATE DETERMINISTIC
   IS
      phase_in_date_ DATE;
   BEGIN
      SELECT eff_phase_in_date
        INTO phase_in_date_
        FROM part_revision
       WHERE part_no = part_no_
         AND eng_chg_level = eng_chg_level_;
      RETURN phase_in_date_;
   EXCEPTION
      WHEN OTHERS THEN
         RETURN NULL;
   END Get_Phase_In_Date___;

   FUNCTION Get_Phase_Out_Date___(
      part_no_       IN VARCHAR,
      eng_chg_level_ IN VARCHAR2) RETURN DATE DETERMINISTIC
   IS
      phase_in_date_ DATE;
   BEGIN
      SELECT eff_phase_out_date
        INTO phase_in_date_
        FROM part_revision
       WHERE part_no = part_no_
         AND eng_chg_level = eng_chg_level_;
      RETURN phase_in_date_;
   EXCEPTION
      WHEN OTHERS THEN
         RETURN NULL;
   END Get_Phase_Out_Date___;
BEGIN
   phase_in_date_:= Get_Phase_In_Date___(part_no_,eng_chg_level_);
   phase_out_date_ := Get_Phase_Out_Date___(part_no_,part_no_);
   hierachy_ := '1' || '<<#>>' || part_no_ || '<<>>' || '' || '<<>>' || eng_chg_level_ || '<<>>' || '' || '<<>>' || contract_;
   Build_Part_Hierachy___(hierachy_,part_no_,contract_,2,phase_in_date_,phase_out_date_);
   RETURN hierachy_;
END Get_Part_Hierachy__; 

FUNCTION Get_Phase_In_Date__(
   part_no_       IN VARCHAR,
   eng_chg_level_ IN VARCHAR2) RETURN DATE DETERMINISTIC
IS
   phase_in_date_ DATE;
BEGIN
   SELECT eff_phase_in_date
     INTO phase_in_date_
     FROM part_revision
    WHERE part_no = part_no_
      AND eng_chg_level = eng_chg_level_;
   RETURN phase_in_date_;
EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END Get_Phase_In_Date__;

FUNCTION Get_Phase_Out_Date__(
   part_no_       IN VARCHAR,
   eng_chg_level_ IN VARCHAR2) RETURN DATE DETERMINISTIC
IS
   phase_in_date_ DATE;
BEGIN
   SELECT eff_phase_out_date
     INTO phase_in_date_
     FROM part_revision
    WHERE part_no = part_no_
      AND eng_chg_level = eng_chg_level_;
   RETURN phase_in_date_;
EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END Get_Phase_Out_Date__;

PROCEDURE Clean_Up_CWU_Report_Multilevel
IS
   stmt_ VARCHAR2(100);
BEGIN
   stmt_ := 
      'BEGIN
         DELETE 
            FROM cwu_report_multilevel_clt;
       END;';
   @ApproveDynamicStatement(2021-07-12,EntPragG)   
   EXECUTE IMMEDIATE stmt_;
END Clean_Up_CWU_Report_Multilevel;
-- C0401 EntPrageG (END)

--C449 EntChamuA (START)
FUNCTION Get_Identity(
   mch_code_ VARCHAR2,
   contract_ VARCHAR2) RETURN VARCHAR2
IS
   return_value_ VARCHAR2(100);
  
   CURSOR get_identity(mch_code_ IN VARCHAR2, contract_ IN VARCHAR2) IS
      SELECT identity
        FROM equipment_object_party_uiv
       WHERE mch_code = mch_code_
         AND contract = contract_;
BEGIN
   OPEN get_identity(mch_code_, contract_);
   FETCH get_identity INTO return_value_;
   IF(get_identity%NOTFOUND)THEN
      return_value_ := '';
   END IF;
   CLOSE get_identity;
   
   RETURN return_value_;
END Get_Identity;
--C449 EntChamuA (END)

-- C0449 EntChamuA (START)
FUNCTION Get_Contract_Id(
   mch_code_ VARCHAR2,
   contract_ VARCHAR2) RETURN VARCHAR2
IS
   return_value_ VARCHAR2(100);
   
   CURSOR get_contract_id (mch_code_ IN VARCHAR2, contract_ IN VARCHAR2) IS
      SELECT DISTINCT cp.contract_id
      FROM psc_contr_product_uiv cp
      WHERE connection_type_db IN ('EQUIPMENT', 'CATEGORY', 'PART')
      AND (EXISTS (SELECT 1
         FROM psc_srv_line_objects t
         WHERE t.contract_id = cp.contract_id
         AND t.line_no = cp.line_no
         AND (t.mch_code, t.mch_contract) IN
         (SELECT mch_code, contract
            FROM Equipment_All_Object_Uiv
            START WITH mch_code = mch_code_
            AND contract = contract_
            CONNECT BY PRIOR mch_code = sup_mch_code
            AND PRIOR contract = sup_contract)));

BEGIN
   
   OPEN get_contract_id(mch_code_, contract_);
   FETCH get_contract_id INTO return_value_;
   CLOSE get_contract_id;
   RETURN return_value_;
END Get_Contract_Id;
--  C0049 EntChamuA (END)  

--C0457 EntNadeeL (START) 
PROCEDURE Create_Demand_Forecast_ 
IS
   sql_stmt_          VARCHAR2(32000);
   pivot_clause_      CLOB;
   pivot_clause_date_ CLOB;
BEGIN
   SELECT LISTAGG('''' || replace(monthname||'-'||year,' ','') || '''',',') WITHIN GROUP(ORDER BY year,month ASC)
     INTO pivot_clause_
     FROM (SELECT DISTINCT to_char(to_date(Work_Time_Calendar_API.Get_Work_Day(Period_Template_API.Get_Calendar_Id(t.contract,t.template_id),t.period_begin_counter),'DD/MM/YYYY'), 'YY') AS year,
                  to_char(to_date(Work_Time_Calendar_API.Get_Work_Day(Period_Template_API.Get_Calendar_Id(t.contract,t.template_id),t.period_begin_counter),'DD/MM/YYYY'), 'MM') AS month , 
                  to_char(to_date(Work_Time_Calendar_API.Get_Work_Day(Period_Template_API.Get_Calendar_Id(t.contract,t.template_id),t.period_begin_counter),'DD/MM/YYYY'), 'Month') AS monthname     
             FROM period_template_detail t
            WHERE t.template_id = '14'
              AND to_date(Work_Time_Calendar_API.Get_Work_Day(Period_Template_API.Get_Calendar_Id(t.contract,t.template_id),t.period_begin_counter), 'DD/MM/YYYY') BETWEEN
                  to_date(SYSDATE, 'DD/MM/YYYY') AND
                  add_months(to_date(SYSDATE, 'DD/MM/YYYY'), 14)
                  AND t.contract = '2011'
                  ORDER BY year,month);
                  
    Transaction_Sys.Set_Status_Info(pivot_clause_,'INFO');       
                  
 
   sql_stmt_ := 'CREATE OR REPLACE VIEW DEMAND_FORECAST_TEMP_QRY AS
                  SELECT  *
                  FROM (SELECT  t.contract,
                                Inventory_Part_Api.Get_Prime_Commodity(t.contract,t.part_no) AS "Comm Group",
                                t.part_no AS "Part No",
                                Inventory_Part_Api.Get_Description(t.contract,t.part_no) AS "Description",
                                replace(to_char(ms_date,''Month'')||''-''||to_char(ms_date,''YY''), '' '', '''') AS month,
                                t.forecast_lev0,
                                t.forecast_lev1 
                          FROM level_1_forecast t
                         WHERE t.ms_set = 1
                           AND to_date(t.ms_date, ''DD/MM/YYYY'') >= to_date(SYSDATE, ''DD/MM/YYYY'')
                      ORDER BY "Comm Group" ASC)                  
                         PIVOT (SUM(forecast_lev0) AS forecast0,
                           SUM(forecast_lev1) AS forecast1 FOR month IN (' ||pivot_clause_|| '))';  
   Transaction_Sys.Set_Status_Info( sql_stmt_,'INFO');
   @ApproveDynamicStatement(2021-07-27,EntNadeeL)
   EXECUTE IMMEDIATE sql_stmt_;   
END Create_Demand_Forecast_; 
--C0457 EntNadeeL (END)

-- C0436 EntPrageG (START)
FUNCTION Get_Document_Title__(
   key_ref_ IN VARCHAR2) RETURN VARCHAR2
IS
   doc_class_ VARCHAR2(20);
   doc_no_ VARCHAR2(20);
   doc_sheet_ NUMBER;
   doc_rev_ VARCHAR2(10);
   title_ VARCHAR2(100);
BEGIN
   Get_Document_Keys_From_Key_Ref___(doc_class_,doc_no_,doc_sheet_,doc_rev_,key_ref_);
   
   SELECT title
     INTO title_
     FROM doc_issue_reference
    WHERE doc_class = doc_class_
      AND doc_no = doc_no_
      AND doc_sheet = doc_sheet_
      AND doc_rev = doc_rev_;
   RETURN title_;
EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END Get_Document_Title__;  

FUNCTION Get_Doc_Resp_Person__ (
   key_ref_ IN VARCHAR2) RETURN VARCHAR2
IS
BEGIN
   RETURN Person_Info_API.Get_Name(Get_Doc_Resp_Person___(key_ref_));
END Get_Doc_Resp_Person__;

FUNCTION Get_Doc_Resp_Per_Email__(
   key_ref_ IN VARCHAR2) RETURN VARCHAR2
IS
   resp_per_ VARCHAR2(50);
   email_ VARCHAR2(50);
BEGIN
   resp_per_:= Get_Doc_Resp_Person___(key_ref_);
   email_:= Comm_Method_API.Get_Comm_Method('PERSON',resp_per_,'E_MAIL',SYSDATE);   
   RETURN email_;
END Get_Doc_Resp_Per_Email__;
-- C0436 EntPrageG (END)

-- C364 EntNadeeL (START)
PROCEDURE Create_Supp_Forecast_View_ IS
  sql_stmt              VARCHAR2(32000);
  pivot_clause          CLOB; 
  pivot_clause_date     CLOB; 
BEGIN
  SELECT LISTAGG('''' || to_date(forecast, 'DD/MM/YYYY') || '''' , ',') WITHIN GROUP (ORDER BY to_date(forecast, 'DD/MM/YYYY') ASC) 
  INTO pivot_clause_date
  FROM   (SELECT *
          FROM (SELECT *
                  FROM (SELECT t.cf$_part_no,
                               t.cf$_supplier_no,t.cf$_week_str_01,t.cf$_week_str_02,t.cf$_week_str_03,t.cf$_week_str_04,t.cf$_week_str_05,t.cf$_week_str_06,t.cf$_week_str_07,t.cf$_week_str_08,
                               t.cf$_week_str_09,t.cf$_week_str_10,t.cf$_week_str_11,t.cf$_week_str_12,t.cf$_week_str_13,t.cf$_week_str_14,t.cf$_week_str_15,t.cf$_week_str_16,t.cf$_week_str_17,
                               t.cf$_week_str_18,t.cf$_week_str_19,t.cf$_week_str_20,t.cf$_week_str_21,t.cf$_week_str_22,t.cf$_week_str_23,t.cf$_week_str_24,t.cf$_week_str_25,t.cf$_week_str_26,
                               t.cf$_week_str_27,t.cf$_week_str_28,t.cf$_week_str_29,t.cf$_week_str_30,t.cf$_week_str_31,t.cf$_week_str_32,t.cf$_week_str_33,t.cf$_week_str_34,t.cf$_week_str_35,
                               t.cf$_week_str_36,t.cf$_week_str_37,t.cf$_week_str_38,t.cf$_week_str_39,t.cf$_week_str_40,t.cf$_week_str_41,t.cf$_week_str_42,t.cf$_week_str_43,t.cf$_week_str_44,
                               t.cf$_week_str_45,t.cf$_week_str_46,t.cf$_week_str_47,t.cf$_week_str_48,t.cf$_week_str_49,t.cf$_week_str_50,t.cf$_week_str_51,t.cf$_week_str_52,t.cf$_week_str_53,
							          t.cf$_week_str_54,t.cf$_week_str_55,t.cf$_week_str_56,t.cf$_week_str_57,t.cf$_week_str_58,t.cf$_week_str_59,t.cf$_week_str_60,t.cf$_week_str_61,t.cf$_week_str_62,
                               t.cf$_week_str_63,t.cf$_week_str_64,t.cf$_week_str_65,t.cf$_week_str_66,t.cf$_week_str_67,t.cf$_week_str_68,t.cf$_week_str_69,t.cf$_week_str_70,t.cf$_week_str_71,
                               t.cf$_week_str_72,t.cf$_week_str_73,t.cf$_week_str_74,t.cf$_week_str_75,t.cf$_week_str_76,t.cf$_week_str_77,t.cf$_week_str_78,t.cf$_week_str_79
                               
                          FROM supplier_forecast_clv t) a UNPIVOT(forecast FOR week IN(cf$_week_str_01,cf$_week_str_02,cf$_week_str_03,cf$_week_str_04,cf$_week_str_05,cf$_week_str_06,cf$_week_str_07,
                                cf$_week_str_08,cf$_week_str_09,cf$_week_str_10,cf$_week_str_11,cf$_week_str_12,cf$_week_str_13,cf$_week_str_14,cf$_week_str_15,cf$_week_str_16,cf$_week_str_17,
                                cf$_week_str_18,cf$_week_str_19,cf$_week_str_20,cf$_week_str_21,cf$_week_str_22,cf$_week_str_23,cf$_week_str_24,cf$_week_str_25,cf$_week_str_26,cf$_week_str_27,
                                cf$_week_str_28,cf$_week_str_29,cf$_week_str_30,cf$_week_str_31,cf$_week_str_32,cf$_week_str_33,cf$_week_str_34,cf$_week_str_35,cf$_week_str_36,cf$_week_str_37,
                                cf$_week_str_38,cf$_week_str_39,cf$_week_str_40,cf$_week_str_41,cf$_week_str_42,cf$_week_str_43,cf$_week_str_44,cf$_week_str_45,cf$_week_str_46,cf$_week_str_47,
                                cf$_week_str_48,cf$_week_str_49,cf$_week_str_50,cf$_week_str_51,cf$_week_str_52,cf$_week_str_53,cf$_week_str_54,cf$_week_str_55,cf$_week_str_56,cf$_week_str_57,
                                cf$_week_str_58,cf$_week_str_59,cf$_week_str_60,cf$_week_str_61,cf$_week_str_62,cf$_week_str_63,cf$_week_str_64,cf$_week_str_65,cf$_week_str_66,cf$_week_str_67,
                                cf$_week_str_68,cf$_week_str_69,cf$_week_str_70,cf$_week_str_71,cf$_week_str_72,cf$_week_str_73,cf$_week_str_74,cf$_week_str_75,cf$_week_str_76,cf$_week_str_77,
                                cf$_week_str_78,cf$_week_str_79))
                 ORDER BY cf$_supplier_no) b
         WHERE cf$_supplier_no IS NULL AND
         b.forecast IN
               (SELECT forecast
                  FROM (SELECT *
                          FROM (SELECT t.cf$_part_no,
                               t.cf$_supplier_no,t.cf$_week_str_01,t.cf$_week_str_02,t.cf$_week_str_03,t.cf$_week_str_04,t.cf$_week_str_05,t.cf$_week_str_06,t.cf$_week_str_07,t.cf$_week_str_08,
                               t.cf$_week_str_09,t.cf$_week_str_10,t.cf$_week_str_11,t.cf$_week_str_12,t.cf$_week_str_13,t.cf$_week_str_14,t.cf$_week_str_15,t.cf$_week_str_16,t.cf$_week_str_17,
                               t.cf$_week_str_18,t.cf$_week_str_19,t.cf$_week_str_20,t.cf$_week_str_21,t.cf$_week_str_22,t.cf$_week_str_23,t.cf$_week_str_24,t.cf$_week_str_25,t.cf$_week_str_26,
                               t.cf$_week_str_27,t.cf$_week_str_28,t.cf$_week_str_29,t.cf$_week_str_30,t.cf$_week_str_31,t.cf$_week_str_32,t.cf$_week_str_33,t.cf$_week_str_34,t.cf$_week_str_35,
                               t.cf$_week_str_36,t.cf$_week_str_37,t.cf$_week_str_38,t.cf$_week_str_39,t.cf$_week_str_40,t.cf$_week_str_41,t.cf$_week_str_42,t.cf$_week_str_43,t.cf$_week_str_44,
                               t.cf$_week_str_45,t.cf$_week_str_46,t.cf$_week_str_47,t.cf$_week_str_48,t.cf$_week_str_49,t.cf$_week_str_50,t.cf$_week_str_51,t.cf$_week_str_52,t.cf$_week_str_53,
							          t.cf$_week_str_54,t.cf$_week_str_55,t.cf$_week_str_56,t.cf$_week_str_57,t.cf$_week_str_58,t.cf$_week_str_59,t.cf$_week_str_60,t.cf$_week_str_61,t.cf$_week_str_62,
                               t.cf$_week_str_63,t.cf$_week_str_64,t.cf$_week_str_65,t.cf$_week_str_66,t.cf$_week_str_67,t.cf$_week_str_68,t.cf$_week_str_69,t.cf$_week_str_70,t.cf$_week_str_71,
                               t.cf$_week_str_72,t.cf$_week_str_73,t.cf$_week_str_74,t.cf$_week_str_75,t.cf$_week_str_76,t.cf$_week_str_77,t.cf$_week_str_78,t.cf$_week_str_79
                               
                                FROM supplier_forecast_clv t) a UNPIVOT(forecast FOR week IN(cf$_week_str_01,cf$_week_str_02,cf$_week_str_03,cf$_week_str_04,cf$_week_str_05,cf$_week_str_06,cf$_week_str_07,
                                cf$_week_str_08,cf$_week_str_09,cf$_week_str_10,cf$_week_str_11,cf$_week_str_12,cf$_week_str_13,cf$_week_str_14,cf$_week_str_15,cf$_week_str_16,cf$_week_str_17,
                                cf$_week_str_18,cf$_week_str_19,cf$_week_str_20,cf$_week_str_21,cf$_week_str_22,cf$_week_str_23,cf$_week_str_24,cf$_week_str_25,cf$_week_str_26,cf$_week_str_27,
                                cf$_week_str_28,cf$_week_str_29,cf$_week_str_30,cf$_week_str_31,cf$_week_str_32,cf$_week_str_33,cf$_week_str_34,cf$_week_str_35,cf$_week_str_36,cf$_week_str_37,
                                cf$_week_str_38,cf$_week_str_39,cf$_week_str_40,cf$_week_str_41,cf$_week_str_42,cf$_week_str_43,cf$_week_str_44,cf$_week_str_45,cf$_week_str_46,cf$_week_str_47,
                                cf$_week_str_48,cf$_week_str_49,cf$_week_str_50,cf$_week_str_51,cf$_week_str_52,cf$_week_str_53,cf$_week_str_54,cf$_week_str_55,cf$_week_str_56,cf$_week_str_57,
                                cf$_week_str_58,cf$_week_str_59,cf$_week_str_60,cf$_week_str_61,cf$_week_str_62,cf$_week_str_63,cf$_week_str_64,cf$_week_str_65,cf$_week_str_66,cf$_week_str_67,
                                cf$_week_str_68,cf$_week_str_69,cf$_week_str_70,cf$_week_str_71,cf$_week_str_72,cf$_week_str_73,cf$_week_str_74,cf$_week_str_75,cf$_week_str_76,cf$_week_str_77,
                                cf$_week_str_78,cf$_week_str_79))
                         ORDER BY cf$_supplier_no)
                 WHERE CF$_supplier_no is null
                   AND to_date(forecast, 'DD/MM/YYYY') > trunc(SYSDATE) - 7));
                   
  SELECT LISTAGG('''' || week || '''' , ',') WITHIN GROUP (ORDER BY week) 
  INTO   pivot_clause
  FROM   (SELECT DISTINCT week
          FROM (SELECT *
                  FROM (SELECT t.cf$_part_no,
                               t.cf$_supplier_no,t.cf$_week_str_01,t.cf$_week_str_02,t.cf$_week_str_03,t.cf$_week_str_04,t.cf$_week_str_05,t.cf$_week_str_06,t.cf$_week_str_07,t.cf$_week_str_08,
                               t.cf$_week_str_09,t.cf$_week_str_10,t.cf$_week_str_11,t.cf$_week_str_12,t.cf$_week_str_13,t.cf$_week_str_14,t.cf$_week_str_15,t.cf$_week_str_16,t.cf$_week_str_17,
                               t.cf$_week_str_18,t.cf$_week_str_19,t.cf$_week_str_20,t.cf$_week_str_21,t.cf$_week_str_22,t.cf$_week_str_23,t.cf$_week_str_24,t.cf$_week_str_25,t.cf$_week_str_26,
                               t.cf$_week_str_27,t.cf$_week_str_28,t.cf$_week_str_29,t.cf$_week_str_30,t.cf$_week_str_31,t.cf$_week_str_32,t.cf$_week_str_33,t.cf$_week_str_34,t.cf$_week_str_35,
                               t.cf$_week_str_36,t.cf$_week_str_37,t.cf$_week_str_38,t.cf$_week_str_39,t.cf$_week_str_40,t.cf$_week_str_41,t.cf$_week_str_42,t.cf$_week_str_43,t.cf$_week_str_44,
                               t.cf$_week_str_45,t.cf$_week_str_46,t.cf$_week_str_47,t.cf$_week_str_48,t.cf$_week_str_49,t.cf$_week_str_50,t.cf$_week_str_51,t.cf$_week_str_52,t.cf$_week_str_53,
							          t.cf$_week_str_54,t.cf$_week_str_55,t.cf$_week_str_56,t.cf$_week_str_57,t.cf$_week_str_58,t.cf$_week_str_59,t.cf$_week_str_60,t.cf$_week_str_61,t.cf$_week_str_62,
                               t.cf$_week_str_63,t.cf$_week_str_64,t.cf$_week_str_65,t.cf$_week_str_66,t.cf$_week_str_67,t.cf$_week_str_68,t.cf$_week_str_69,t.cf$_week_str_70,t.cf$_week_str_71,
                               t.cf$_week_str_72,t.cf$_week_str_73,t.cf$_week_str_74,t.cf$_week_str_75,t.cf$_week_str_76,t.cf$_week_str_77,t.cf$_week_str_78,t.cf$_week_str_79
                               
                          FROM supplier_forecast_clv t) a UNPIVOT(forecast FOR week IN(cf$_week_str_01,cf$_week_str_02,cf$_week_str_03,cf$_week_str_04,cf$_week_str_05,cf$_week_str_06,cf$_week_str_07,
                                cf$_week_str_08,cf$_week_str_09,cf$_week_str_10,cf$_week_str_11,cf$_week_str_12,cf$_week_str_13,cf$_week_str_14,cf$_week_str_15,cf$_week_str_16,cf$_week_str_17,
                                cf$_week_str_18,cf$_week_str_19,cf$_week_str_20,cf$_week_str_21,cf$_week_str_22,cf$_week_str_23,cf$_week_str_24,cf$_week_str_25,cf$_week_str_26,cf$_week_str_27,
                                cf$_week_str_28,cf$_week_str_29,cf$_week_str_30,cf$_week_str_31,cf$_week_str_32,cf$_week_str_33,cf$_week_str_34,cf$_week_str_35,cf$_week_str_36,cf$_week_str_37,
                                cf$_week_str_38,cf$_week_str_39,cf$_week_str_40,cf$_week_str_41,cf$_week_str_42,cf$_week_str_43,cf$_week_str_44,cf$_week_str_45,cf$_week_str_46,cf$_week_str_47,
                                cf$_week_str_48,cf$_week_str_49,cf$_week_str_50,cf$_week_str_51,cf$_week_str_52,cf$_week_str_53,cf$_week_str_54,cf$_week_str_55,cf$_week_str_56,cf$_week_str_57,
                                cf$_week_str_58,cf$_week_str_59,cf$_week_str_60,cf$_week_str_61,cf$_week_str_62,cf$_week_str_63,cf$_week_str_64,cf$_week_str_65,cf$_week_str_66,cf$_week_str_67,
                                cf$_week_str_68,cf$_week_str_69,cf$_week_str_70,cf$_week_str_71,cf$_week_str_72,cf$_week_str_73,cf$_week_str_74,cf$_week_str_75,cf$_week_str_76,cf$_week_str_77,
                                cf$_week_str_78,cf$_week_str_79))
                 ORDER BY cf$_supplier_no) b
         WHERE cf$_supplier_no IS NOT NULL AND
         b.week IN
               (SELECT week
                  FROM (SELECT *
                          FROM (SELECT t.cf$_part_no,
                                       t.cf$_supplier_no,t.cf$_week_str_01,t.cf$_week_str_02,t.cf$_week_str_03,t.cf$_week_str_04,t.cf$_week_str_05,t.cf$_week_str_06,t.cf$_week_str_07,t.cf$_week_str_08,
                               t.cf$_week_str_09,t.cf$_week_str_10,t.cf$_week_str_11,t.cf$_week_str_12,t.cf$_week_str_13,t.cf$_week_str_14,t.cf$_week_str_15,t.cf$_week_str_16,t.cf$_week_str_17,
                               t.cf$_week_str_18,t.cf$_week_str_19,t.cf$_week_str_20,t.cf$_week_str_21,t.cf$_week_str_22,t.cf$_week_str_23,t.cf$_week_str_24,t.cf$_week_str_25,t.cf$_week_str_26,
                               t.cf$_week_str_27,t.cf$_week_str_28,t.cf$_week_str_29,t.cf$_week_str_30,t.cf$_week_str_31,t.cf$_week_str_32,t.cf$_week_str_33,t.cf$_week_str_34,t.cf$_week_str_35,
                               t.cf$_week_str_36,t.cf$_week_str_37,t.cf$_week_str_38,t.cf$_week_str_39,t.cf$_week_str_40,t.cf$_week_str_41,t.cf$_week_str_42,t.cf$_week_str_43,t.cf$_week_str_44,
                               t.cf$_week_str_45,t.cf$_week_str_46,t.cf$_week_str_47,t.cf$_week_str_48,t.cf$_week_str_49,t.cf$_week_str_50,t.cf$_week_str_51,t.cf$_week_str_52,t.cf$_week_str_53,
							          t.cf$_week_str_54,t.cf$_week_str_55,t.cf$_week_str_56,t.cf$_week_str_57,t.cf$_week_str_58,t.cf$_week_str_59,t.cf$_week_str_60,t.cf$_week_str_61,t.cf$_week_str_62,
                               t.cf$_week_str_63,t.cf$_week_str_64,t.cf$_week_str_65,t.cf$_week_str_66,t.cf$_week_str_67,t.cf$_week_str_68,t.cf$_week_str_69,t.cf$_week_str_70,t.cf$_week_str_71,
                               t.cf$_week_str_72,t.cf$_week_str_73,t.cf$_week_str_74,t.cf$_week_str_75,t.cf$_week_str_76,t.cf$_week_str_77,t.cf$_week_str_78,t.cf$_week_str_79
                               
                                  FROM supplier_forecast_clv t) a UNPIVOT(forecast FOR week IN(cf$_week_str_01,cf$_week_str_02,cf$_week_str_03,cf$_week_str_04,cf$_week_str_05,cf$_week_str_06,cf$_week_str_07,
                                cf$_week_str_08,cf$_week_str_09,cf$_week_str_10,cf$_week_str_11,cf$_week_str_12,cf$_week_str_13,cf$_week_str_14,cf$_week_str_15,cf$_week_str_16,cf$_week_str_17,
                                cf$_week_str_18,cf$_week_str_19,cf$_week_str_20,cf$_week_str_21,cf$_week_str_22,cf$_week_str_23,cf$_week_str_24,cf$_week_str_25,cf$_week_str_26,cf$_week_str_27,
                                cf$_week_str_28,cf$_week_str_29,cf$_week_str_30,cf$_week_str_31,cf$_week_str_32,cf$_week_str_33,cf$_week_str_34,cf$_week_str_35,cf$_week_str_36,cf$_week_str_37,
                                cf$_week_str_38,cf$_week_str_39,cf$_week_str_40,cf$_week_str_41,cf$_week_str_42,cf$_week_str_43,cf$_week_str_44,cf$_week_str_45,cf$_week_str_46,cf$_week_str_47,
                                cf$_week_str_48,cf$_week_str_49,cf$_week_str_50,cf$_week_str_51,cf$_week_str_52,cf$_week_str_53,cf$_week_str_54,cf$_week_str_55,cf$_week_str_56,cf$_week_str_57,
                                cf$_week_str_58,cf$_week_str_59,cf$_week_str_60,cf$_week_str_61,cf$_week_str_62,cf$_week_str_63,cf$_week_str_64,cf$_week_str_65,cf$_week_str_66,cf$_week_str_67,
                                cf$_week_str_68,cf$_week_str_69,cf$_week_str_70,cf$_week_str_71,cf$_week_str_72,cf$_week_str_73,cf$_week_str_74,cf$_week_str_75,cf$_week_str_76,cf$_week_str_77,
                                cf$_week_str_78,cf$_week_str_79))
                         ORDER BY cf$_supplier_no)
                 WHERE cf$_supplier_no IS NULL
                   AND to_date(forecast, 'DD/MM/YYYY') > trunc(SYSDATE) - 7));
 
  sql_stmt := 'CREATE OR REPLACE VIEW SUPPLIER_FORECAST_TEMP_QRY AS   
SELECT *
  FROM (SELECT *
          FROM (SELECT *
                  FROM (SELECT t.cf$_part_no AS "Part No",
                               t.cf$_part_description AS "Part Description",
                               t.cf$_supplier_no AS "Supplier No",
                               t.cf$_supplier_name AS "Supplier Name",
                               t.cf$_forecast_date AS "Forecast Date",
                               t.cf$_manufacturer_id AS "Manufacturer",
                               t.cf$_manufacturer_part_no AS "Manufacturer Part No",
                               t.cf$_req_or_order AS "Req or Order",
                               t.cf$_week_qty_00 AS "Week Qty Overdue",
                               t.cf$_week_str_01,t.cf$_week_str_02,t.cf$_week_str_03,t.cf$_week_str_04,t.cf$_week_str_05,t.cf$_week_str_06,t.cf$_week_str_07,t.cf$_week_str_08,
                               t.cf$_week_str_09,t.cf$_week_str_10,t.cf$_week_str_11,t.cf$_week_str_12,t.cf$_week_str_13,t.cf$_week_str_14,t.cf$_week_str_15,t.cf$_week_str_16,t.cf$_week_str_17,
                               t.cf$_week_str_18,t.cf$_week_str_19,t.cf$_week_str_20,t.cf$_week_str_21,t.cf$_week_str_22,t.cf$_week_str_23,t.cf$_week_str_24,t.cf$_week_str_25,t.cf$_week_str_26,
                               t.cf$_week_str_27,t.cf$_week_str_28,t.cf$_week_str_29,t.cf$_week_str_30,t.cf$_week_str_31,t.cf$_week_str_32,t.cf$_week_str_33,t.cf$_week_str_34,t.cf$_week_str_35,
                               t.cf$_week_str_36,t.cf$_week_str_37,t.cf$_week_str_38,t.cf$_week_str_39,t.cf$_week_str_40,t.cf$_week_str_41,t.cf$_week_str_42,t.cf$_week_str_43,t.cf$_week_str_44,
                               t.cf$_week_str_45,t.cf$_week_str_46,t.cf$_week_str_47,t.cf$_week_str_48,t.cf$_week_str_49,t.cf$_week_str_50,t.cf$_week_str_51,t.cf$_week_str_52,t.cf$_week_str_53,
							          t.cf$_week_str_54,t.cf$_week_str_55,t.cf$_week_str_56,t.cf$_week_str_57,t.cf$_week_str_58,t.cf$_week_str_59,t.cf$_week_str_60,t.cf$_week_str_61,t.cf$_week_str_62,
                               t.cf$_week_str_63,t.cf$_week_str_64,t.cf$_week_str_65,t.cf$_week_str_66,t.cf$_week_str_67,t.cf$_week_str_68,t.cf$_week_str_69,t.cf$_week_str_70,t.cf$_week_str_71,
                               t.cf$_week_str_72,t.cf$_week_str_73,t.cf$_week_str_74,t.cf$_week_str_75,t.cf$_week_str_76,t.cf$_week_str_77,t.cf$_week_str_78,t.cf$_week_str_79
                               
                          FROM supplier_forecast_clv t) a UNPIVOT(forecast FOR week IN(cf$_week_str_01,cf$_week_str_02,cf$_week_str_03,cf$_week_str_04,cf$_week_str_05,cf$_week_str_06,cf$_week_str_07,
                                cf$_week_str_08,cf$_week_str_09,cf$_week_str_10,cf$_week_str_11,cf$_week_str_12,cf$_week_str_13,cf$_week_str_14,cf$_week_str_15,cf$_week_str_16,cf$_week_str_17,
                                cf$_week_str_18,cf$_week_str_19,cf$_week_str_20,cf$_week_str_21,cf$_week_str_22,cf$_week_str_23,cf$_week_str_24,cf$_week_str_25,cf$_week_str_26,cf$_week_str_27,
                                cf$_week_str_28,cf$_week_str_29,cf$_week_str_30,cf$_week_str_31,cf$_week_str_32,cf$_week_str_33,cf$_week_str_34,cf$_week_str_35,cf$_week_str_36,cf$_week_str_37,
                                cf$_week_str_38,cf$_week_str_39,cf$_week_str_40,cf$_week_str_41,cf$_week_str_42,cf$_week_str_43,cf$_week_str_44,cf$_week_str_45,cf$_week_str_46,cf$_week_str_47,
                                cf$_week_str_48,cf$_week_str_49,cf$_week_str_50,cf$_week_str_51,cf$_week_str_52,cf$_week_str_53,cf$_week_str_54,cf$_week_str_55,cf$_week_str_56,cf$_week_str_57,
                                cf$_week_str_58,cf$_week_str_59,cf$_week_str_60,cf$_week_str_61,cf$_week_str_62,cf$_week_str_63,cf$_week_str_64,cf$_week_str_65,cf$_week_str_66,cf$_week_str_67,
                                cf$_week_str_68,cf$_week_str_69,cf$_week_str_70,cf$_week_str_71,cf$_week_str_72,cf$_week_str_73,cf$_week_str_74,cf$_week_str_75,cf$_week_str_76,cf$_week_str_77,
                                cf$_week_str_78,cf$_week_str_79))) b
         WHERE "Supplier No" IS NULL AND
         b.forecast IN
               (SELECT forecast
                  FROM (SELECT *
                          FROM (SELECT t.cf$_part_no AS "Part No",
                               t.cf$_part_description AS "Part Description",
                               t.cf$_supplier_no AS "Supplier No",
                               t.cf$_supplier_name AS "Supplier Name",
                               t.cf$_forecast_date AS "Forecast Date",
                               t.cf$_manufacturer_id AS "Manufacturer",
                               t.cf$_manufacturer_part_no AS "Manufacturer Part No",
                               t.cf$_req_or_order AS "Req or Order",
                               t.cf$_week_qty_00 AS "Week Qty Overdue",t.cf$_week_str_01,t.cf$_week_str_02,t.cf$_week_str_03,t.cf$_week_str_04,t.cf$_week_str_05,t.cf$_week_str_06,t.cf$_week_str_07,t.cf$_week_str_08,
                               t.cf$_week_str_09,t.cf$_week_str_10,t.cf$_week_str_11,t.cf$_week_str_12,t.cf$_week_str_13,t.cf$_week_str_14,t.cf$_week_str_15,t.cf$_week_str_16,t.cf$_week_str_17,
                               t.cf$_week_str_18,t.cf$_week_str_19,t.cf$_week_str_20,t.cf$_week_str_21,t.cf$_week_str_22,t.cf$_week_str_23,t.cf$_week_str_24,t.cf$_week_str_25,t.cf$_week_str_26,
                               t.cf$_week_str_27,t.cf$_week_str_28,t.cf$_week_str_29,t.cf$_week_str_30,t.cf$_week_str_31,t.cf$_week_str_32,t.cf$_week_str_33,t.cf$_week_str_34,t.cf$_week_str_35,
                               t.cf$_week_str_36,t.cf$_week_str_37,t.cf$_week_str_38,t.cf$_week_str_39,t.cf$_week_str_40,t.cf$_week_str_41,t.cf$_week_str_42,t.cf$_week_str_43,t.cf$_week_str_44,
                               t.cf$_week_str_45,t.cf$_week_str_46,t.cf$_week_str_47,t.cf$_week_str_48,t.cf$_week_str_49,t.cf$_week_str_50,t.cf$_week_str_51,t.cf$_week_str_52,t.cf$_week_str_53,
							                 t.cf$_week_str_54,t.cf$_week_str_55,t.cf$_week_str_56,t.cf$_week_str_57,t.cf$_week_str_58,t.cf$_week_str_59,t.cf$_week_str_60,t.cf$_week_str_61,t.cf$_week_str_62,
                               t.cf$_week_str_63,t.cf$_week_str_64,t.cf$_week_str_65,t.cf$_week_str_66,t.cf$_week_str_67,t.cf$_week_str_68,t.cf$_week_str_69,t.cf$_week_str_70,t.cf$_week_str_71,
                               t.cf$_week_str_72,t.cf$_week_str_73,t.cf$_week_str_74,t.cf$_week_str_75,t.cf$_week_str_76,t.cf$_week_str_77,t.cf$_week_str_78,t.cf$_week_str_79
                               
                                  FROM supplier_forecast_clv t) a UNPIVOT(forecast FOR week IN(cf$_week_str_01,cf$_week_str_02,cf$_week_str_03,cf$_week_str_04,cf$_week_str_05,cf$_week_str_06,cf$_week_str_07,
                                cf$_week_str_08,cf$_week_str_09,cf$_week_str_10,cf$_week_str_11,cf$_week_str_12,cf$_week_str_13,cf$_week_str_14,cf$_week_str_15,cf$_week_str_16,cf$_week_str_17,
                                cf$_week_str_18,cf$_week_str_19,cf$_week_str_20,cf$_week_str_21,cf$_week_str_22,cf$_week_str_23,cf$_week_str_24,cf$_week_str_25,cf$_week_str_26,cf$_week_str_27,
                                cf$_week_str_28,cf$_week_str_29,cf$_week_str_30,cf$_week_str_31,cf$_week_str_32,cf$_week_str_33,cf$_week_str_34,cf$_week_str_35,cf$_week_str_36,cf$_week_str_37,
                                cf$_week_str_38,cf$_week_str_39,cf$_week_str_40,cf$_week_str_41,cf$_week_str_42,cf$_week_str_43,cf$_week_str_44,cf$_week_str_45,cf$_week_str_46,cf$_week_str_47,
                                cf$_week_str_48,cf$_week_str_49,cf$_week_str_50,cf$_week_str_51,cf$_week_str_52,cf$_week_str_53,cf$_week_str_54,cf$_week_str_55,cf$_week_str_56,cf$_week_str_57,
                                cf$_week_str_58,cf$_week_str_59,cf$_week_str_60,cf$_week_str_61,cf$_week_str_62,cf$_week_str_63,cf$_week_str_64,cf$_week_str_65,cf$_week_str_66,cf$_week_str_67,
                                cf$_week_str_68,cf$_week_str_69,cf$_week_str_70,cf$_week_str_71,cf$_week_str_72,cf$_week_str_73,cf$_week_str_74,cf$_week_str_75,cf$_week_str_76,cf$_week_str_77,
                                cf$_week_str_78,cf$_week_str_79)))
                 WHERE "Supplier No" IS NULL
                   AND 
                   to_date(forecast, ''DD/MM/YYYY'') > trunc(SYSDATE) - 7))  
                   PIVOT (COUNT(forecast) FOR week IN ('||pivot_clause_date||'))

UNION 
SELECT *
  FROM (SELECT *
          FROM (SELECT *
                  FROM (SELECT t.cf$_part_no AS "Part No",
                               t.cf$_part_description AS "Part Description",
                               t.cf$_supplier_no AS "Supplier No",
                               t.cf$_supplier_name AS "Supplier Name",
                               t.cf$_forecast_date AS "Forecast Date",
                               t.cf$_manufacturer_id AS "Manufacturer",
                               t.cf$_manufacturer_part_no AS "Manufacturer Part No",
                               t.cf$_req_or_order AS "Req or Order",
                               t.cf$_week_qty_00 AS "Week Qty Overdue",t.cf$_week_str_01,t.cf$_week_str_02,t.cf$_week_str_03,t.cf$_week_str_04,t.cf$_week_str_05,t.cf$_week_str_06,t.cf$_week_str_07,t.cf$_week_str_08,
                               t.cf$_week_str_09,t.cf$_week_str_10,t.cf$_week_str_11,t.cf$_week_str_12,t.cf$_week_str_13,t.cf$_week_str_14,t.cf$_week_str_15,t.cf$_week_str_16,t.cf$_week_str_17,
                               t.cf$_week_str_18,t.cf$_week_str_19,t.cf$_week_str_20,t.cf$_week_str_21,t.cf$_week_str_22,t.cf$_week_str_23,t.cf$_week_str_24,t.cf$_week_str_25,t.cf$_week_str_26,
                               t.cf$_week_str_27,t.cf$_week_str_28,t.cf$_week_str_29,t.cf$_week_str_30,t.cf$_week_str_31,t.cf$_week_str_32,t.cf$_week_str_33,t.cf$_week_str_34,t.cf$_week_str_35,
                               t.cf$_week_str_36,t.cf$_week_str_37,t.cf$_week_str_38,t.cf$_week_str_39,t.cf$_week_str_40,t.cf$_week_str_41,t.cf$_week_str_42,t.cf$_week_str_43,t.cf$_week_str_44,
                               t.cf$_week_str_45,t.cf$_week_str_46,t.cf$_week_str_47,t.cf$_week_str_48,t.cf$_week_str_49,t.cf$_week_str_50,t.cf$_week_str_51,t.cf$_week_str_52,t.cf$_week_str_53,
							                 t.cf$_week_str_54,t.cf$_week_str_55,t.cf$_week_str_56,t.cf$_week_str_57,t.cf$_week_str_58,t.cf$_week_str_59,t.cf$_week_str_60,t.cf$_week_str_61,t.cf$_week_str_62,
                               t.cf$_week_str_63,t.cf$_week_str_64,t.cf$_week_str_65,t.cf$_week_str_66,t.cf$_week_str_67,t.cf$_week_str_68,t.cf$_week_str_69,t.cf$_week_str_70,t.cf$_week_str_71,
                               t.cf$_week_str_72,t.cf$_week_str_73,t.cf$_week_str_74,t.cf$_week_str_75,t.cf$_week_str_76,t.cf$_week_str_77,t.cf$_week_str_78,t.cf$_week_str_79
                               
                          FROM supplier_forecast_clv t) a UNPIVOT(forecast FOR week IN(cf$_week_str_01,cf$_week_str_02,cf$_week_str_03,cf$_week_str_04,cf$_week_str_05,cf$_week_str_06,cf$_week_str_07,
                                cf$_week_str_08,cf$_week_str_09,cf$_week_str_10,cf$_week_str_11,cf$_week_str_12,cf$_week_str_13,cf$_week_str_14,cf$_week_str_15,cf$_week_str_16,cf$_week_str_17,
                                cf$_week_str_18,cf$_week_str_19,cf$_week_str_20,cf$_week_str_21,cf$_week_str_22,cf$_week_str_23,cf$_week_str_24,cf$_week_str_25,cf$_week_str_26,cf$_week_str_27,
                                cf$_week_str_28,cf$_week_str_29,cf$_week_str_30,cf$_week_str_31,cf$_week_str_32,cf$_week_str_33,cf$_week_str_34,cf$_week_str_35,cf$_week_str_36,cf$_week_str_37,
                                cf$_week_str_38,cf$_week_str_39,cf$_week_str_40,cf$_week_str_41,cf$_week_str_42,cf$_week_str_43,cf$_week_str_44,cf$_week_str_45,cf$_week_str_46,cf$_week_str_47,
                                cf$_week_str_48,cf$_week_str_49,cf$_week_str_50,cf$_week_str_51,cf$_week_str_52,cf$_week_str_53,cf$_week_str_54,cf$_week_str_55,cf$_week_str_56,cf$_week_str_57,
                                cf$_week_str_58,cf$_week_str_59,cf$_week_str_60,cf$_week_str_61,cf$_week_str_62,cf$_week_str_63,cf$_week_str_64,cf$_week_str_65,cf$_week_str_66,cf$_week_str_67,
                                cf$_week_str_68,cf$_week_str_69,cf$_week_str_70,cf$_week_str_71,cf$_week_str_72,cf$_week_str_73,cf$_week_str_74,cf$_week_str_75,cf$_week_str_76,cf$_week_str_77,
                                cf$_week_str_78,cf$_week_str_79))) b
         WHERE "Supplier No" IS NOT NULL AND
         b.WEEK IN
               (SELECT week
                  FROM (SELECT *
                          FROM (SELECT t.cf$_part_no AS "Part No",
                               t.cf$_part_description AS "Part Description",
                               t.cf$_supplier_no AS "Supplier No",
                               t.cf$_supplier_name AS "Supplier Name",
                               t.cf$_forecast_date AS "Forecast Date",
                               t.cf$_manufacturer_id AS "Manufacturer",
                               t.cf$_manufacturer_part_no AS "Manufacturer Part No",
                               t.cf$_req_or_order AS "Req or Order",
                               t.cf$_week_qty_00 AS "Week Qty Overdue",t.cf$_week_str_01,t.cf$_week_str_02,t.cf$_week_str_03,t.cf$_week_str_04,t.cf$_week_str_05,t.cf$_week_str_06,t.cf$_week_str_07,t.cf$_week_str_08,
                               t.cf$_week_str_09,t.cf$_week_str_10,t.cf$_week_str_11,t.cf$_week_str_12,t.cf$_week_str_13,t.cf$_week_str_14,t.cf$_week_str_15,t.cf$_week_str_16,t.cf$_week_str_17,
                               t.cf$_week_str_18,t.cf$_week_str_19,t.cf$_week_str_20,t.cf$_week_str_21,t.cf$_week_str_22,t.cf$_week_str_23,t.cf$_week_str_24,t.cf$_week_str_25,t.cf$_week_str_26,
                               t.cf$_week_str_27,t.cf$_week_str_28,t.cf$_week_str_29,t.cf$_week_str_30,t.cf$_week_str_31,t.cf$_week_str_32,t.cf$_week_str_33,t.cf$_week_str_34,t.cf$_week_str_35,
                               t.cf$_week_str_36,t.cf$_week_str_37,t.cf$_week_str_38,t.cf$_week_str_39,t.cf$_week_str_40,t.cf$_week_str_41,t.cf$_week_str_42,t.cf$_week_str_43,t.cf$_week_str_44,
                               t.cf$_week_str_45,t.cf$_week_str_46,t.cf$_week_str_47,t.cf$_week_str_48,t.cf$_week_str_49,t.cf$_week_str_50,t.cf$_week_str_51,t.cf$_week_str_52,t.cf$_week_str_53,
							                 t.cf$_week_str_54,t.cf$_week_str_55,t.cf$_week_str_56,t.cf$_week_str_57,t.cf$_week_str_58,t.cf$_week_str_59,t.cf$_week_str_60,t.cf$_week_str_61,t.cf$_week_str_62,
                               t.cf$_week_str_63,t.cf$_week_str_64,t.cf$_week_str_65,t.cf$_week_str_66,t.cf$_week_str_67,t.cf$_week_str_68,t.cf$_week_str_69,t.cf$_week_str_70,t.cf$_week_str_71,
                               t.cf$_week_str_72,t.cf$_week_str_73,t.cf$_week_str_74,t.cf$_week_str_75,t.cf$_week_str_76,t.cf$_week_str_77,t.cf$_week_str_78,t.cf$_week_str_79
                               
                                  FROM supplier_forecast_clv t) a UNPIVOT(forecast FOR week IN(cf$_week_str_01,cf$_week_str_02,cf$_week_str_03,cf$_week_str_04,cf$_week_str_05,cf$_week_str_06,cf$_week_str_07,
                                cf$_week_str_08,cf$_week_str_09,cf$_week_str_10,cf$_week_str_11,cf$_week_str_12,cf$_week_str_13,cf$_week_str_14,cf$_week_str_15,cf$_week_str_16,cf$_week_str_17,
                                cf$_week_str_18,cf$_week_str_19,cf$_week_str_20,cf$_week_str_21,cf$_week_str_22,cf$_week_str_23,cf$_week_str_24,cf$_week_str_25,cf$_week_str_26,cf$_week_str_27,
                                cf$_week_str_28,cf$_week_str_29,cf$_week_str_30,cf$_week_str_31,cf$_week_str_32,cf$_week_str_33,cf$_week_str_34,cf$_week_str_35,cf$_week_str_36,cf$_week_str_37,
                                cf$_week_str_38,cf$_week_str_39,cf$_week_str_40,cf$_week_str_41,cf$_week_str_42,cf$_week_str_43,cf$_week_str_44,cf$_week_str_45,cf$_week_str_46,cf$_week_str_47,
                                cf$_week_str_48,cf$_week_str_49,cf$_week_str_50,cf$_week_str_51,cf$_week_str_52,cf$_week_str_53,cf$_week_str_54,cf$_week_str_55,cf$_week_str_56,cf$_week_str_57,
                                cf$_week_str_58,cf$_week_str_59,cf$_week_str_60,cf$_week_str_61,cf$_week_str_62,cf$_week_str_63,cf$_week_str_64,cf$_week_str_65,cf$_week_str_66,cf$_week_str_67,
                                cf$_week_str_68,cf$_week_str_69,cf$_week_str_70,cf$_week_str_71,cf$_week_str_72,cf$_week_str_73,cf$_week_str_74,cf$_week_str_75,cf$_week_str_76,cf$_week_str_77,
                                cf$_week_str_78,cf$_week_str_79)))
                 WHERE "Supplier No" IS NULL
                   AND to_date(forecast,''DD/MM/YYYY'') > trunc(SYSDATE) - 7))                  
PIVOT (SUM(to_number(forecast)) FOR week IN ('||pivot_clause||'))';

 EXECUTE IMMEDIATE sql_stmt;
END Create_Supp_Forecast_View_;
-- C364 EntNadeeL (END)

--210728 EntNadeeL C0567 (START) 
PROCEDURE Create_Weekly_Loading_ IS
 sql_stmt          VARCHAR2(32000);
   pivot_clause      CLOB;
   pivot_clause_date CLOB;
BEGIN
   SELECT LISTAGG('''' || ms_date || '''',',') WITHIN GROUP(ORDER BY ms_date ASC)
   INTO pivot_clause
   FROM (SELECT DISTINCT to_date(Work_Time_Calendar_API.Get_Work_Day(Period_Template_API.Get_Calendar_Id(t.contract,t.template_id),t.period_end_counter),'DD/MM/YYYY') AS ms_date
          FROM PERIOD_TEMPLATE_DETAIL t
         WHERE t.template_id = '8'
           AND t.period_begin_counter >= 0
           AND to_date(Work_Time_Calendar_API.Get_Work_Day(Period_Template_API.Get_Calendar_Id(t.contract,t.template_id),t.period_end_counter),'DD/MM/YYYY') BETWEEN to_date(SYSDATE, 'DD/MM/YYYY') AND
               to_date(SYSDATE, 'DD/MM/YYYY') + (18 * 7));
 Transaction_Sys.Set_Status_Info(pivot_clause,'INFO');
   sql_stmt := 'CREATE OR REPLACE VIEW WEEKLY_LOADING_TEMP_QRY AS
            SELECT *
  FROM (SELECT 
       to_date(Work_Time_Calendar_API.Get_Work_Day(Period_Template_API.Get_Calendar_Id(t.contract,t.template_id),t.period_end_counter),''DD/MM/YY'') AS ms_date,
       CASE
                  WHEN to_date(SYSDATE, ''DD/MM/YYYY'') BETWEEN
                       to_date(Work_Time_Calendar_API.Get_Work_Day(Period_Template_API.Get_Calendar_Id(t.contract,t.template_id),t.period_begin_counter),''DD/MM/YYYY'') AND
                       to_date(Work_Time_Calendar_API.Get_Work_Day(Period_Template_API.Get_Calendar_Id(t.contract,t.template_id),t.period_end_counter),''DD/MM/YYYY'') THEN
                   ROUND(((to_date(Work_Time_Calendar_API.Get_Work_Day(Period_Template_API.Get_Calendar_Id(t.contract,t.template_id),t.period_end_counter),''DD/MM/YYYY'') -
                         to_date(SYSDATE, ''DD/MM/YYYY'') - 1) * 7.75 + 4.25),2)
                  ELSE
                   ROUND(((to_date(Work_Time_Calendar_API.Get_Work_Day(Period_Template_API.Get_Calendar_Id(t.contract,t.template_id),t.period_end_counter),''DD/MM/YYYY'') -
                         to_date(Work_Time_Calendar_API.Get_Work_Day(Period_Template_API.Get_Calendar_Id(t.contract,t.template_id),t.period_begin_counter), ''DD/MM/YYYY'')) * 7.75 + 4.25) ,2)
               END left_days,
               '''' AS "Contract",
               '''' AS "Product Family",
               '''' AS "Part No",
               '''' AS "Description",
               '''' AS "Product Code"
          FROM PERIOD_TEMPLATE_DETAIL t
         WHERE t.template_id = ''8''
           AND t.period_begin_counter >= 0
           AND to_date(Work_Time_Calendar_API.Get_Work_Day(Period_Template_API.Get_Calendar_Id(t.contract,t.template_id),t.period_end_counter),''DD/MM/YYYY'') BETWEEN to_date(SYSDATE, ''DD/MM/YYYY'') AND
               to_date(SYSDATE, ''DD/MM/YYYY'') + (18 * 7)) 
               PIVOT(SUM(left_days) FOR ms_date IN(' ||pivot_clause|| '))
               
               UNION ALL

SELECT *
  FROM (SELECT 
       to_date(Work_Time_Calendar_API.Get_Work_Day(Period_Template_API.Get_Calendar_Id(t.contract,t.template_id),t.period_end_counter),''DD/MM/YY'') AS ms_date,
       CASE
                  WHEN to_date(SYSDATE, ''DD/MM/YYYY'') BETWEEN
                       to_date(Work_Time_Calendar_API.Get_Work_Day(Period_Template_API.Get_Calendar_Id(t.contract,t.template_id),t.period_begin_counter),''DD/MM/YYYY'') AND
                       to_date(Work_Time_Calendar_API.Get_Work_Day(Period_Template_API.Get_Calendar_Id(t.contract,t.template_id),t.period_end_counter),''DD/MM/YYYY'') THEN
                   ROUND(((to_date(Work_Time_Calendar_API.Get_Work_Day(Period_Template_API.Get_Calendar_Id(t.contract,t.template_id),t.period_end_counter),''DD/MM/YYYY'') -
                         to_date(SYSDATE, ''DD/MM/YYYY'') - 1) * 7.75 + 4.25) / 7.75,2)
                  ELSE
                   ROUND(((to_date(Work_Time_Calendar_API.Get_Work_Day(Period_Template_API.Get_Calendar_Id(t.contract,t.template_id),t.period_end_counter),''DD/MM/YYYY'') -
                         to_date(Work_Time_Calendar_API.Get_Work_Day(Period_Template_API.Get_Calendar_Id(t.contract,t.template_id),t.period_begin_counter), ''DD/MM/YYYY'')) * 7.75 + 4.25) / 7.75,2)
               END left_days,
               '''' AS "Contract",
               '''' AS "Product Family",
               '''' AS "Part No",
               '''' AS "Description",
               '''' AS "Product Code"
          FROM PERIOD_TEMPLATE_DETAIL t
         WHERE t.template_id = ''8''
           AND t.period_begin_counter >= 0
           AND to_date(Work_Time_Calendar_API.Get_Work_Day(Period_Template_API.Get_Calendar_Id(t.contract,t.template_id),t.period_end_counter),''DD/MM/YYYY'') BETWEEN to_date(SYSDATE, ''DD/MM/YYYY'') AND
               to_date(SYSDATE, ''DD/MM/YYYY'') + (18 * 7)) 
               PIVOT(SUM(left_days) FOR ms_date IN(' ||pivot_clause|| '))
               
            UNION ALL

         SELECT  *
         FROM (SELECT   t.contract,
         ifsapp.Inventory_Product_Family_API.Get_Description(ifsapp.Inventory_Part_Api.Get_Part_Product_Family(t.contract,t.part_no)) "Product Family",
            t.part_no AS "Part No",
            Inventory_Part_Api.Get_Description(t.contract,t.part_no) AS "Description",
            ifsapp.Inventory_Part_Api.Get_Part_Product_Code(t.contract,t.part_no) "Product Code",
            to_date(t.ms_date,''DD/MM/YY'') AS ms_date,                
            t.supply
         FROM level_1_forecast t
         WHERE t.ms_set = 1
         AND to_date(t.ms_date, ''DD/MM/YY'') >= to_date(SYSDATE, ''DD/MM/YY'')
         ORDER BY "Product Family" ASC)                  
         PIVOT ( SUM(supply) FOR ms_date IN (' ||pivot_clause|| '))';  

   EXECUTE IMMEDIATE sql_stmt;     
END Create_Weekly_Loading_;
--210728 EntNadeeL C0567 (END) 
-------------------- LU  NEW METHODS -------------------------------------
