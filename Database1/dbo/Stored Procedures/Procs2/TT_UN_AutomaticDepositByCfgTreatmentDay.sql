/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_AutomaticDepositByCfgTreatmentDay
Description         :	Procédure générant automatiquement les CPA à envoyé à la banque selon la configuration qu'on
								retrouve dans la table Un_AutomaticDepositTreatmentCfg
Valeurs de retours  :	@ReturnValue :
									> 0 : Le traitement a réussi.
									<= 0: Le traitement a échouée.
Note                :	ADX0000532	IA	2004-10-13	Bruno Lapointe		Création
								ADX0000532	IA	2004-10-13	Bruno Lapointe		12.56 - Modification pour qu'elle fonctionne avec
														la configuration de la table Un_AutomaticDepositTreatmentCfg au lieu que par
														jour ouvrable.
								ADX0000720	IA	2005-07-19	Bruno Lapointe		Modifier le nom de la procédure. 
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_AutomaticDepositByCfgTreatmentDay]
AS
BEGIN
	-- Valeur de retour
	-- >=0 : Traitement effectué avec succès
	--			0  : Pas de traitement à effectuer
	--			>0 : Correspond au ID du dernier traitement effectué.
	-- <0  : Erreurs
	--			Correspond aux erreurs de la procédure stockée SP_TT_UN_AutomaticDepositInTwoDate
	DECLARE
		@Result INTEGER,
		@LastBankFileEndDate DATETIME,
		@LastDateToDo DATETIME,
		@TreatmentDate DATETIME

	SET @Result = 0

	-- Vérifie qu'il doit y avoir un traitement ce jour
	IF EXISTS (
		SELECT TreatmentDay
		FROM Un_AutomaticDepositTreatmentCfg
		WHERE DATEPART(dw, GETDATE()) = TreatmentDay)
	BEGIN
		-- Va chercher le nombre de jour à ajouter à la date du jour pour connaître jusqu'à qu'elle jour il faut traiter.
		SELECT 
			@LastDateToDo = DATEADD(DAY, DaysAfterToTreat+DaysAddForNextTreatment, dbo.fn_Mo_DateNoTime(GETDATE()))
		FROM Un_AutomaticDepositTreatmentCfg
		WHERE DATEPART(dw, GETDATE()) = TreatmentDay
	
		-- Va chercher le dernier jour traité, si c'est le premier fichier traité ce sera la date du jour
		SET @LastBankFileEndDate = dbo.fn_Mo_DateNoTime(GETDATE())
		SELECT
			@LastBankFileEndDate = MAX(BankFileEndDate)
		FROM Un_BankFile

		-- Vérifie s'il y a des traitements à faire
		IF @LastDateToDo > @LastBankFileEndDate
		BEGIN
			-- Premier jour traité sera le lendemain du dernier traité.
			SET @TreatmentDate = DATEADD(DAY, 1, @LastBankFileEndDate)
			-- Effectue tout les traitements à faire un jour à la fois
			WHILE (@TreatmentDate <= @LastDateToDo)
			  AND (@Result >= 0)
			BEGIN
				-- Ne doit pas être un 29, 30 ou 31
				IF DAY(@TreatmentDate) <= 28
					-- Lance le traitement
					EXECUTE @Result = TT_UN_AutomaticDepositInTwoDate 1, @TreatmentDate, @TreatmentDate
				-- Passe au jour suivant
				SET @TreatmentDate = DATEADD(DAY, 1, @TreatmentDate)
			END
		END
	END
END

