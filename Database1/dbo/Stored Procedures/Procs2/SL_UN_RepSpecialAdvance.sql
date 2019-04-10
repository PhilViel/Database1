/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_RepSpecialAdvance
Description         :	Procédure retournant l'historique des avances spéciales pour une représentant.
Valeurs de retours  :	Dataset :		SpecialAdvanceID	INTEGER		ID unique de l’avance spéciale.
						RepID			INTEGER		ID du représentant.
						EffectDate		DATETIME	Date d’effectivité de l'avance spéciale.
						Amount			MONEY		Montant de l'avance spéciale.
						vcSpecialAdvanceDesc	VARCHAR(100)	Champ contenant la description justifiant l’avance spéciale.
						RepTreatmentID		INTEGER		ID unique du traitement de commissions (Un_RepTreatment) qui a généré 
											cette avance spéciale. Null = Entrée manuelle.

Note                :	ADX0000735	IA	2005-05-19	Pierre-Michel Bussière	Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_RepSpecialAdvance] (
	@RepID INTEGER ) -- ID du représentant.
AS
BEGIN
	SELECT
		SpecialAdvanceID,
		RepID,
		EffectDate,
		Amount,
		vcSpecialAdvanceDesc,
		RepTreatmentID
	FROM Un_SpecialAdvance
	WHERE RepID = @RepID
	ORDER BY EffectDate DESC, Amount ASC
END

