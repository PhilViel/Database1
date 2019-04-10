/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 : SP_IU_UN_ConventionYearQualif
Description         : Sauvegarde d'ajouts d'historique d'année de qualification
Valeurs de retours  : >0  :	Tout à fonctionné
                      <=0 :	Erreur SQL
								-1	: Erreur lors de la sauvegarde de l'ajout
								-2 : Cette année de qualification est déjà en vigueur pour cette convention
Note                :	ADX0000612	IA	2005-01-03	Bruno Lapointe		Création
								ADX0001602	BR	2005-10-11	Bruno Lapointe		SCOPE_IDENTITY au lieu de IDENT_CURRENT
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_IU_UN_ConventionYearQualif] (
	@ConnectID INTEGER, -- ID unique de connexion de l'usager qui a fait la modification
	@ConventionID INTEGER, -- ID unique de la convention
	@YearQualif INTEGER) -- Année de qualification
AS
BEGIN
	DECLARE
		@iConventionYearQualifID INTEGER,
		@dtEffectDate DATETIME

	IF NOT EXISTS (
		SELECT ConventionID
		FROM Un_ConventionYearQualif
		WHERE 	ConventionID = @ConventionID
			AND	YearQualif = @YearQualif
			AND	TerminatedDate IS NULL)
	BEGIN
		SET @dtEffectDate = GetDate()

		-- Met la date de fin sur l'historique en vigueur
		UPDATE Un_ConventionYearQualif
		SET
			TerminatedDate = DATEADD(ms, -2, @dtEffectDate)
		WHERE ConventionID = @ConventionID
			AND	TerminatedDate IS NULL

		-- Insère le nouvel historique
		INSERT INTO Un_ConventionYearQualif (ConventionID, ConnectID, EffectDate, YearQualif)
		VALUES (@ConventionID, @ConnectID, @dtEffectDate, @YearQualif)

		IF @@ERROR <> 0
			-- Erreur SQL lors de la sauvegarde de l'ajout 
			SET @iConventionYearQualifID = -1
		ELSE
			SET @iConventionYearQualifID = SCOPE_IDENTITY()
	END
	ELSE
		-- Cette année de qualification est déjà en vigueur
		SET @iConventionYearQualifID = -2

	RETURN @iConventionYearQualifID
END


