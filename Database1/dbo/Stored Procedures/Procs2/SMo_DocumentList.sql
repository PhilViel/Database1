CREATE PROCEDURE SMo_DocumentList
/*
 Recherche une liste de Document en fonction d'une liste de Classes
 EX : TMoCustom;TMoAdr;TMoHuman
*/
 (@ConnectID        MoID)
AS
BEGIN
  /* Recherche les Doc membre */
  SELECT
    DG.DocGroupID,
    DG.DocGroupName,
    DG.DocGroupDesc,
    DG.DocGroupClassName,
    DGD.DocGroupDtlID,
    DOC.*,
    DS.DocSourceProcName,
    DS.DocSourceClassName,
    DL.DocLangID,
    DL.DocLangDestDir,
    DL.DocLangDestName,
    DL.DocLangSourceName,
    DS.DocSourceType
  FROM Mo_DocumentGroup DG
    LEFT JOIN Mo_DocumentGroupDtl DGD ON (DGD.DocGroupID = DG.DocGroupID)
    LEFT JOIN Mo_Document DOC ON (DOC.DocID = DGD.DocID)
    LEFT JOIN Mo_DocumentSource DS ON (DS.DocSourceID = DOC.DocSourceID)
    LEFT JOIN Mo_DocumentLang DL ON (DL.DocID = DOC.DocID)
  UNION
  SELECT
    DocGroupID = -1,
    DocGroupName = '',
    DocGroupDesc = '',
    DocGroupClassName = '',
    DocGroupDtlID = -1,
    DOC.*,
    DS.DocSourceProcName,
    DS.DocSourceClassName,
    DL.DocLangID,
    DL.DocLangDestDir,
    DL.DocLangDestName,
    DL.DocLangSourceName,
    DS.DocSourceType
  FROM Mo_Document DOC
    JOIN Mo_DocumentSource DS ON (DS.DocSourceID = DOC.DocSourceID)
    JOIN Mo_DocumentLang DL ON (DL.DocID = Doc.DocID)
  WHERE (DOC.DocID NOT IN (SELECT DISTINCT DocID
                           FROM Mo_DocumentGroupDtl) )
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SMo_DocumentList] TO PUBLIC
    AS [dbo];

