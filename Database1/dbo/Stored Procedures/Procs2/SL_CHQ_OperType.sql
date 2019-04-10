/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	SL_CHQ_OperType
Description         :	Procédure qui retournera les types d'opération qui ont genéré des chèques.
Valeurs de retours  :	Dataset :
				vcRefType			VARCHAR(10)		Le type d'opération qui genère le chèque.
Note                :	ADX0000710	IA	2005-08-24	Bernie MacIntyre			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CHQ_OperType]
AS
BEGIN

	SET NOCOUNT ON

	SELECT DISTINCT vcRefType
	FROM CHQ_Operation
	ORDER BY vcRefType
  
END
