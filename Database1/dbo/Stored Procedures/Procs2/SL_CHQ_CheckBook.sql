/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	SL_CHQ_CheckBook 
Description         :	Procédure qui retournera un modèle de chèque.
Valeurs de retours  :	Dataset :
									iCheckBookID		INTEGER 			ID du chéquier.
									vcCheckBookDesc	VARCHAR(255)	Nom du chéquier.
Note                :	ADX0000714	IA	2005-09-16	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CHQ_CheckBook] 
AS
BEGIN
	SELECT 
		iCheckBookID, -- ID du chéquier.
		vcCheckBookDesc -- Nom du chéquier.
	FROM CHQ_CheckBook
END
