
/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 				:	IU_UN_RepBusinessBonusCfg
Description 		:	Ajout ou modification d’une configuration de bonis d’affaires
Valeurs de retour	:	@ReturnValue :
							> 0 : [Réussite]
							<= 0 : [Échec].

Notes :		ADX0001260	IA	2007-03-23	Alain Quirion		Création
*********************************************************************************/
CREATE PROCEDURE dbo.IU_UN_RepBusinessBonusCfg(
	@RepBusinessBonusCfgID INTEGER,		--ID de la configuration (<0 = Insertion)
	@StartDate DATETIME,				--Date de début
	@EndDate DATETIME,					--Date de fin
	@BusinessBonusByUnit MONEY,			--Boni par unité
	@BusinessBonusNbrOfYears INTEGER,		--No. Max de bonis
	@RepRoleID CHAR(3),					--ID du rôle (‘CAB’ = cabinet de courtage, ‘DIR’ = directeur, ‘REP’= représentant, ‘DCC’ = directeur de cabinet de courtage, ‘DEV’ = directeur de développement, ‘PRO’= directeur des ventes, ‘PRS’ = directeur des ventes sans commissions, ‘DIS’ = directeur sans commissions, ‘VES’ = vendeur sans commissions)
	@InsurTypeID CHAR(3))				--ID du type d’assurance (‘ISB’ = Souscripteur, ‘IB1’ = Bénéficiaire 10000, ‘IB2’ = Bénéficiaire 20000)
AS
BEGIN
	DECLARE @iResult INTEGER

	SET @iResult = 1

	IF @RepBusinessBonusCfgID <= 0
	BEGIN
		INSERT INTO Un_RepBusinessBonusCfg(
				StartDate,
				EndDate,					
				BusinessBonusByUnit ,	
				BusinessBonusNbrOfYears,		
				RepRoleID,					
				InsurTypeID)
		VALUES(	@StartDate,
				@EndDate,					
				@BusinessBonusByUnit,	
				@BusinessBonusNbrOfYears,		
				@RepRoleID,					
				@InsurTypeID)

		IF @@ERROR <> 0
			SET @iResult = -1
		ELSE
			SET @iResult = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
		UPDATE Un_RepBusinessBonusCfg
		SET StartDate = @StartDate,
			EndDate = @EndDate,					
			BusinessBonusByUnit = @BusinessBonusByUnit,	
			BusinessBonusNbrOfYears = @BusinessBonusNbrOfYears,		
			RepRoleID = @RepRoleID,					
			InsurTypeID = @InsurTypeID
		WHERE RepBusinessBonusCfgID = @RepBusinessBonusCfgID

		IF @@ERROR <> 0
			SET @iResult = -2
		ELSE
			SET @iResult = @RepBusinessBonusCfgID
	END

	RETURN @iResult
END

