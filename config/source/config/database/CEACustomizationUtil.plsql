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
   v_project_id_ VARCHAR2(20);
   v_sub_project_id_ VARCHAR2(20);
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
      project_id_:= :v_project_id_;
      sub_project_id_ := :v_sub_project_id_;
      
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
   v_project_id_:= v_project_id_;
   v_sub_project_id_ := v_sub_project_id_;
   
   IF (Database_SYS.View_Exist('WARRANTY_CLV') 
          AND Database_SYS.View_Exist('SALES_CONTRACT_SITE_CLV')
             AND Database_SYS.View_Exist('PROJECT_CFV')) THEN
      @ApproveDynamicStatement('2021-06-07',EntPrageG);
      EXECUTE IMMEDIATE stmt_
      USING IN v_project_id_,
            IN v_sub_project_id_;
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
      --@ApproveDynamicStatement('2021-04-27',entpragg);
      EXECUTE IMMEDIATE stmt_
        USING IN part_no_, IN part_rev_;
   ELSE
      Error_Sys.Appl_General(lu_name_, 'Custom Objects are not published!');
   END IF;   
END Copy_Circuit_Reference__;
--C0628 EntPrageG (END)
-------------------- LU  NEW METHODS -------------------------------------
