
/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 				:	SL_UN_RepBusinessBonusCfg
Description 		:	Renvoi la liste des configurations de bonis d’affaires des représentants
Valeurs de retour	:	Dataset :
							RepBusinessBonusCfgID	INTEGER		ID de la configuration
							StartDate				DATETIME	Date de début
							EndDate					DATETIME	Date de fin
							BusinessBonusByUnit		MONEY		Boni par unité	
							BusinessBonusNbrYears	INTEGER		No. Max de bonis
							RepRoleID				CHAR(3)		ID du rôle (‘CAB’ = cabinet de courtage, ‘DIR’ = directeur, ‘REP’= représentant, ‘DCC’ = directeur de cabinet de courtage, ‘DEV’ = directeur de développement, ‘PRO’= directeur des ventes, ‘PRS’ = directeur des ventes sans commissions, ‘DIS’ = directeur sans commissions, ‘VES’ = vendeur sans commissions)
							RepRoleDesc				VARCHAR(75)	Rôle 		
							InsurTypeID				CHAR(3)		ID du type d’assurance (‘ISB’ = Souscripteur, ‘IB1’ = Bénéficiaire 10000, ‘IB2’ = Bénéficiaire 20000)
							InsurType				VARCHAR(50)	Type d’assurance

Notes				:	ADX0001260	IA	2007-03-23	Alain Quirion		Création
*********************************************************************************/
CREATE PROCEDURE dbo.SL_UN_RepBusinessBonusCfg(
	@RepRoleID	CHAR(3))	-- ID du rôle
AS
BEGIN
	SELECT
		RBB.RepBusinessBonusCfgID,	--ID de la configuration
		RBB.StartDate,				--Date de début
		RBB.EndDate,				--Date de fin
		RBB.BusinessBonusByUnit,	--Boni par unité	
		RBB.BusinessBonusNbrOfYears,--No. Max de bonis
		RBB.RepRoleID,				--ID du rôle (‘CAB’ = cabinet de courtage, ‘DIR’ = directeur, ‘REP’= représentant, ‘DCC’ = directeur de cabinet de courtage, ‘DEV’ = directeur de développement, ‘PRO’= directeur des ventes, ‘PRS’ = directeur des ventes sans commissions, ‘DIS’ = directeur sans commissions, ‘VES’ = vendeur sans commissions)
		RR.RepRoleDesc,				--Rôle 		
		RBB.InsurTypeID			--ID du type d’assurance (‘ISB’ = Souscripteur, ‘IB1’ = Bénéficiaire 10000, ‘IB2’ = Bénéficiaire 20000)
	FROM Un_RepBusinessBonusCfg RBB
	JOIN Un_RepRole RR ON RR.RepRoleID = RBB.RepRoleID
	WHERE RBB.RepRoleID = @RepRoleID
			OR @RepRoleID = 'ALL'
	ORDER BY ISNULL(RBB.EndDate,'9999-12-31') DESC, RR.RepRoleDesc ASC, RBB.InsurTypeID ASC
END

