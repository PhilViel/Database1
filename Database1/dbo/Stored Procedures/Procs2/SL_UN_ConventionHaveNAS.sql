/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_ConventionHaveNAS
Description         :	Indique si une convention rempli les deux conditions suivantes :
									o	le NAS du souscripteur est inscrit ou la date d’entrée en vigueur de la convention est 
										avant le 1 janvier 2003, et
									o	le NAS du bénéficiaire est inscrit
Valeurs de retours  :	@ReturnValue :
									> 0 : Réussite
									  1 : Répond aux critères
									= 0 : La convention ne répond pas aux critères
Note                :	ADX0001100	IA	2006-11-13	Bruno Lapointe			Création.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_ConventionHaveNAS] (
	@ConventionID INTEGER)
AS
BEGIN
	IF EXISTS (
			SELECT C.ConventionID
			FROM dbo.Un_Convention C
			JOIN (-- Retrouve la plus petite date d'entrée en vigueur d'un groupe d'unité pour une convention
				SELECT 
					ConventionID,
					InForceDate = MIN(InForceDate)
				FROM dbo.Un_Unit 
				WHERE ConventionID = @ConventionID
				GROUP BY ConventionID
				) I ON I.ConventionID = C.ConventionID
			JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
			JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
			WHERE C.ConventionID = @ConventionID
				AND( I.InForceDate < '2003-01-01'
					OR dbo.FN_CRI_CheckSin(ISNULL(S.SocialNumber,''), S.IsCompany) = 1
					)
				AND dbo.FN_CRI_CheckSin(ISNULL(B.SocialNumber,''), 0) = 1
			)
		RETURN(1)
	ELSE
		RETURN(0)
END


