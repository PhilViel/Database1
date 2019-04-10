/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_RepCommissionReport 
Description         :	Crée les rapports pour un traitement de commissions.
Valeurs de retours  :	
Note                :	ADX0000696	IA	2005-09-06	Bruno Lapointe		Création
									2016-04-26	Pierre-Luc Simard	Ajout du UnitID et du UnitRepID
                                             2016-10-11     Steeve Picard       Utilisation de «psGENE_IndexEnabledDisabled» pour désactiver & réactiver les index
												
*********************************************************************************************************************/
CREATE PROC [dbo].[TT_UN_RepCommissionReport] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@RepTreatmentID INTEGER ) -- ID du traitement de commissions
AS 
BEGIN
	-- Supprime les Indexes pour plus de rapidité lors de l'insertioh
     EXEC dbo.psGENE_IndexEnabledDisabled 'Un_Dn_RepTreatment', 0
     EXEC dbo.psGENE_IndexEnabledDisabled 'Un_Dn_RepTreatmentSumary', 0

	-- Fait le rapport détaillé
	INSERT INTO Un_Dn_RepTreatment (
			RepTreatmentID,
			RepTreatmentDate,
			RepID,
			FirstDepositDate,
			InforceDate,
			Subscriber,
			ConventionNo,
			RepName,
			RepCode,
			RepLicenseNo,
			RepRoleDesc,
			LevelShortDesc,
			PeriodUnitQty,
			UnitQty,
			TotalFee,
			PeriodAdvance,
			CoverdAdvance,
			CumAdvance,
			ServiceComm,
			PeriodComm,
			CummComm,
			FuturComm,
			BusinessBonus,
			PeriodBusinessBonus,
			CummBusinessBonus,
			FuturBusinessBonus,
			SweepstakeBonusAjust,
			PaidAmount,
			CommExpenses,
			Notes,
			UnitID,
			UnitRepID )
		EXECUTE SL_UN_RepCommissionDetail @RepTreatmentID
 
	-- Fait le rapport sommaire
	INSERT INTO Un_Dn_RepTreatmentSumary (
			RepTreatmentID,
			RepID,
			TreatmentYear,
			RepCode,
			RepName,
			RepTreatmentDate,
			REPPeriodUnit,
			CumREPPeriodUnit,
			DIRPeriodUnit,
			CumDIRPeriodUnit,
			REPConsPct,
			DIRConsPct,
			ConsPct,
			BusinessBonus,
			CoveredAdvance,
			NewAdvance,
			CommANDBonus,
			Adjustment,
			ChqBrut,
			CumChqBrut,
			Retenu,
			ChqNet,
			Mois,
			CumMois,
			Advance,
			FuturCom,
			CommPct) 
		EXECUTE SL_UN_RepCommissionSumary @RepTreatmentID

	-- Recrée les indexes
     EXEC dbo.psGENE_IndexEnabledDisabled 'Un_Dn_RepTreatment', 1
     EXEC dbo.psGENE_IndexEnabledDisabled 'Un_Dn_RepTreatmentSumary', 1
END

