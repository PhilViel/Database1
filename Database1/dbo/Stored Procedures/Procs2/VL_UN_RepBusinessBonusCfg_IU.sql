/*************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 				:	VL_UN_RepBusinessBonusCfg_IU
Description 		:	Validation de l’ajout ou modification d’une configuration de bonis d’affaires

Paramètres d’entrée : Paramètre                     Description
                      --------------------------    -----------------------------------------------------------------
                      RepBusinessBonusCfgID         ID de la configuration (<0 = Insertion)
                      StartDate                     Date de début
                      EndDate                       Date de fin
                      RepRoleID                     ID du rôle  
                                                        ‘CAB’ = cabinet de courtage, 
                                                        ‘DIR’ = directeur, 
                                                        ‘REP’ = représentant, 
                                                        ‘DCC’ = directeur de cabinet de courtage, 
                                                        ‘DEV’ = directeur de développement, 
                                                        ‘PRO’ = directeur des ventes, 
                                                        ‘PRS’ = directeur des ventes sans commissions, 
                                                        ‘DIS’ = directeur sans commissions, 
                                                        ‘VES’ = vendeur sans commissions
                      InsurTypeID                   ID du type d’assurance
                                                        ‘ISB’ = Souscripteur, 
                                                        ‘IB1’ = Bénéficiaire 10000, 
                                                        ‘IB2’ = Bénéficiaire 20000

Valeurs de retour	:	Dataset :
							vcErrorCode	CHAR(3)	Code d’erreur
							vcErrorTex	VARCHAR(200)	Texte de l’erreur
						
						Code d’erreur	Texte de l’erreur
						BB1				Impossible d’avoir deux historiques pour une même période dont 
										le Rôle et le Type d’assurance sont identiques

Notes :		ADX0001260	IA	2007-03-23	Alain Quirion		Création
*********************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_RepBusinessBonusCfg_IU](
	@RepBusinessBonusCfgID INTEGER,
	@StartDate DATETIME,
	@EndDate DATETIME,
	@RepRoleID CHAR(3),
	@InsurTypeID CHAR(3)
) AS
BEGIN
	DECLARE @tError TABLE(
		vcErrorCode VARCHAR(4),
		vcErrorText VARCHAR(255))

	IF @EndDate = 0
		SET @EndDate = NULL

	IF EXISTS (	SELECT * 
				FROM Un_RepBusinessBonusCfg		
				WHERE RepRoleID = @RepRoleID
						AND InsurTypeID = @InsurTypeID
						AND ((ISNULL(EndDate,'9999-12-31') >= @StartDate
								AND StartDate <= @StartDate)
									OR
							(StartDate <= @Enddate
								AND ISNULL(EndDate,'9999-12-31') >= @Enddate))
						AND RepBusinessBonusCfgID <> @RepBusinessBonusCfgID)
	BEGIN
			INSERT INTO @tError
			VALUES( 'BB1', 
					'Impossible d’avoir deux historiques pour une même période dont le Rôle et le Type d’assurance sont identiques.')
	END	

	SELECT *
	FROM @tError 
END
