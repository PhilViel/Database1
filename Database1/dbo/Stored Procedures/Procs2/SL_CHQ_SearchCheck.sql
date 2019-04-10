/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc

Nom                 : SL_CHQ_SearchCheck
Description         : Procédure qui retournera les chèques selon les critères de recherche
Valeurs de retours  : 
Dataset             :

Exemple d’appel     : EXEC [dbo].[SL_CHQ_SearchCheck] 0,NULL,NULL,-1,-1,NULL,NULL,NULL,NULL,2

Historique des modifications:
               Date          Programmeur                        Description
               ------------  ---------------------------------- ---------------------------
ADX0000710  IA 2005-08-24    Bernie MacIntyre                   Création
               2010-06-02    Danielle Côté                      Ajout traitement fiducies distinctes par régime
****************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CHQ_SearchCheck]
   @iCriteriaMask int                -- Masque qui contient les limites de recherche
  ,@dtStartDate datetime             -- La date de début de recherche (chèque)
  ,@dtEndDate datetime               -- La date de fin de recherche (chèque)
  ,@iStartNumber int                 -- Le numéro de début de recherche (chèque)
  ,@iEndNumber int                   -- Le numéro de fin de recherche (chèque)
  ,@vcStatusIDs varchar(200) = NULL  -- Liste délimitée qui contient les IDs de statuts de chèque
  ,@vcOperTypes varchar(2000) = NULL -- Liste délimitée qui contient les types d'opérations
  ,@vcFirstName varchar(200) = NULL  -- Le prénom de la destinataire du chèque
  ,@vcLastName varchar(200) = NULL   -- Le nom de la destinatatire du chèque
  ,@iID_Regroupement_Regime INT      -- ID de regroupement de régimes
AS
BEGIN

   SET NOCOUNT ON

  -- Declare variables
   DECLARE @bCriteria1 bit  -- Date(s) specified
   DECLARE @bCriteria2 bit  -- Check operation type(s) specified
   DECLARE @bCriteria3 bit  -- Lastname and firstname specified
   DECLARE @bCriteria4 bit  -- Firstname and lastname specified
   DECLARE @bCriteria5 bit  -- Check number(s)
   DECLARE @bCriteria6 bit  -- Check status specified

   -- Set the criteria for the search
   SELECT @bCriteria1 = @iCriteriaMask & 1   -- Date(s) specified
   SELECT @bCriteria2 = @iCriteriaMask & 2   -- Check operation type(s) specified
   SELECT @bCriteria3 = @iCriteriaMask & 4   -- Lastname and firstname specified
   SELECT @bCriteria4 = @iCriteriaMask & 8   -- Firstname and lastname specified
   SELECT @bCriteria5 = @iCriteriaMask & 16  -- Check number(s)
   SELECT @bCriteria6 = @iCriteriaMask & 32  -- Check status specified

   -- Firstname and last name are mutually exclusive, so if the first is equal to 1 then the second must be equal to 0, although both may be zero
   IF @bCriteria3 = 1
      SELECT @bCriteria4 = 0

   -- Use default values if none are specified
   SELECT @dtStartDate = ISNULL(dbo.FN_CRQ_IsDateNull(@dtStartDate), '1900/01/01')
   SELECT @dtEndDate = ISNULL(dbo.FN_CRQ_IsDateNull(@dtEndDate), '9999/12/31')

   -- iStartNumber and iEndNumber have -1 as a default value
   IF @iEndNumber <= 0
      SELECT @iEndNumber = 2147483647  -- The maximum allowable positive value for an integer data type

   -- Now perform the select based upon the input criteria
   SELECT C.iCheckID
         ,C.dtEmission
         ,C.iCheckNumber
         ,vcFirstName = ISNULL(H.FirstName,'')
         ,vcLastName = ISNULL(H.LastName,'')
         ,CS.vcStatusDescription
         ,'vcOperType' = CO.vcRefType
         ,C.fAmount
         ,[dbo].[fnCONV_ObtenirCompteFiducie](@iID_Regroupement_Regime) as vcCode_Compte_Comptable_Fiducie
         ,@iID_Regroupement_Regime
     FROM CHQ_Check C
     LEFT JOIN CHQ_Payee P ON P.iPayeeID = C.iPayeeID
     LEFT JOIN dbo.Mo_Human H ON P.iPayeeID = H.HumanID
     LEFT JOIN CHQ_CheckOperationDetail COD ON C.iCheckID = COD.iCheckID
     LEFT JOIN CHQ_Operation CO
     LEFT JOIN CHQ_OperationDetail OD ON CO.iOperationID = OD.iOperationID ON COD.iOperationDetailID = OD.iOperationDetailID
     JOIN CHQ_CheckStatus CS ON C.iCheckStatusID = CS.iCheckStatusID
    WHERE (@bCriteria1 = 0 OR C.dtEmission BETWEEN @dtStartDate AND @dtEndDate)
      AND (@bCriteria2 = 0 OR CO.vcRefType IN (SELECT VarCharValue FROM dbo.FN_CRI_ParseTextToTable(@vcOperTypes, ';')))
      AND (@bCriteria3 = 0 OR ISNULL(H.FirstName,'') LIKE @vcFirstName AND ISNULL(H.Lastname,'') LIKE @vcLastName)
      AND (@bCriteria4 = 0 OR ISNULL(H.FirstName,'') LIKE @vcFirstName AND ISNULL(H.Lastname,'') LIKE @vcLastName)
      AND (@bCriteria5 = 0 OR ISNULL(C.iCheckNumber,0) BETWEEN @iStartNumber AND @iEndNumber)
      AND (@bCriteria6 = 0 OR C.iCheckStatusID IN (SELECT IntegerValue FROM dbo.FN_CRI_ParseTextToTable(@vcStatusIDs, ';')))
      AND C.iID_Regime IN (SELECT iID_Plan FROM [dbo].[fntCONV_ObtenirRegimes](@iID_Regroupement_Regime))
    GROUP BY C.iCheckID
         ,C.dtEmission
         ,C.iCheckNumber
         ,H.FirstName
         ,H.LastName
         ,CS.vcStatusDescription
         ,CO.vcRefType
         ,C.fAmount
         ,C.iCheckStatusID
    ORDER BY 
          CASE
             WHEN @bCriteria1 = 0 THEN 0
             ELSE C.dtEmission
          END
         ,CASE
             WHEN @bCriteria2 = 0 THEN ''
             ELSE CO.vcRefType
          END
         ,CASE
             WHEN @bCriteria3 = 0 THEN ''
             ELSE H.Lastname+H.FirstName
          END
         ,CASE
             WHEN @bCriteria4 = 0 THEN ''
             ELSE H.FirstName+H.Lastname
          END
         ,CASE
             WHEN @bCriteria5 = 0 THEN 0
             ELSE ISNULL(C.iCheckNumber,0)
          END
         ,CASE
             WHEN @bCriteria6 = 0 THEN 0
             ELSE C.iCheckStatusID
          END
         ,C.dtEmission
         ,ISNULL(C.iCheckNumber,0)
         ,H.Lastname
         ,H.FirstName
         ,C.iCheckStatusID
         ,CO.vcRefType

   RETURN 0

END


