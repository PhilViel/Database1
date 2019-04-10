/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	SL_UN_CheckStubWithDetail
Description         :	Liste de la configuration du niveau de détail des talons de chèques
Valeurs de retours  :	Dataset de données
									vcRefType		VARCHAR(10)	Le type d’opération
									bDetailled		BIT			Indique si le talon du chèque en est un détaillé.
Note                :	ADX0001098	IA	2006-09-08	Bruno Lapointe		Création				
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_CheckStubWithDetail] 
AS 
BEGIN
	SELECT DISTINCT 
		O.vcRefType,
		bDetailled = 
			CASE 
				WHEN D.vcRefType IS NULL THEN 0
			ELSE 1
			END
	FROM CHQ_Operation O
	LEFT JOIN CHQ_CheckStubWithDetail D ON D.vcRefType = O.vcRefType
	ORDER BY O.vcRefType
END

