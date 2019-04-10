/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_Program
Description         :	Liste des programmes
Valeurs de retours  :	Dataset :
									ProgramID	INTEGER	Identifiant unique du programme
									ProgramDesc	VARCHAR(75)	Nom du programme.
Note                :						2004-06-07	Bruno Lapointe		Création
								ADX0001320	BR	2005-03-02	Bruno Lapointe		Order de nom de programme
								ADX0000730	IA	2005-06-22	Bruno Lapointe		Enlever le ProgramCode
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_Program] (
	@ProgramID INTEGER ) -- Identifiant unique du programme, 0 = Tous.
AS
BEGIN
	SELECT 
		ProgramID, 
		ProgramDesc
	FROM Un_Program
	WHERE @ProgramID = 0
		OR @ProgramID = ProgramID
	ORDER BY ProgramDesc
END

