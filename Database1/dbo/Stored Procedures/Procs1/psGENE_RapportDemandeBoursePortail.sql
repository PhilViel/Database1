/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */

/****************************************************************************************************
Code de service		:		psGENE_RapportDemandeBoursePortail
Nom du service		:		Rapport demande de bourse / PAE en ligne
But					:		Rapport demande de bourse / PAE en ligne
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------

Exemple d'appel:
                
				EXEC psGENE_RapportDemandeBoursePortail '2011-10-01', '2012-02-13'

Parametres de sortie :	Champs						Description
						-----------------			---------------------------	
						iIDBeneficiaire				ID bénéficiaire
						vcNomBeneficiaire			Nom bénéficiaire
						vcPrenomBeneficiaire		Prénom bénéficiaire
						vcTypeDocumentSoumis		Type de document soumis
						vcConventions				Info conventions
                   
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2011-08-17					Eric Michaud							Création du service
						2012-02-13					Donald Huppé							GLPI 6910 : Refonte complète du rapport
                        2017-09-27                  Pierre-Luc Simard                       Deprecated - Cette procédure n'est plus utilisée

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_RapportDemandeBoursePortail]
			(
			@dtDateDebut DATETIME,
			@dtDateFin	DATETIME
			)
AS
BEGIN

    SELECT 1/0
    /*
	SET NOCOUNT ON

		SELECT 
			P.iIDBeneficiaire,
			Beneficiaire = hb.LastName + ', ' + hb.FirstName,
			Pl.PlanDesc,
			c.ConventionNo,
			Souscripteur = hs.LastName + ', ' + hs.FirstName,
			DateReceptionDemande = P.dtDateCreationDemande,
			P.vcNoConfirmation,
			P.vcBourse,
			P.vcCommentaires,
			vcTypeDocumentSoumis = 
				CASE 
					WHEN isnull(vcPreuveInscription,'') <> '' and isnull(vcPreuveReleve,'') <> '' then 'Relevé de note et preuve d''inscription'
					WHEN isnull(vcPreuveInscription,'') <> '' and isnull(vcPreuveReleve,'') = '' then 'Preuve d''inscription'
					WHEN isnull(vcPreuveInscription,'') = '' and isnull(vcPreuveReleve,'') <> '' then 'Relevé de note'
				END,
				
			ProchaineBourse = isnull(max(b.ScholarshipNo),0) + 1
			 
		from 
			tblGENE_DemandeBoursePortail P
			JOIN dbo.Mo_Human hb ON P.iIDBeneficiaire = hb.HumanID
			JOIN dbo.Un_Convention c ON  P.iIDBeneficiaire = c.BeneficiaryID AND CHARINDEX ( c.ConventionNo ,P.vcConventions , 1 ) > 0
			JOIN Un_Plan Pl ON c.PlanID = Pl.PlanID
			JOIN dbo.Mo_Human hs ON c.SubscriberID = hs.HumanID
			LEFT JOIN Un_Scholarship b on c.conventionid = b.conventionid AND b.scholarshipstatusid = 'PAD'
			LEFT JOIN Un_ScholarshipPmt Bp on Bp.ScholarshipID = b.ScholarshipID
			LEFT JOIN un_oper op on bp.operid = op.operid 

		WHERE 
			1=1
			AND LEFT(CONVERT(VARCHAR, P.dtDateCreationDemande, 120), 10) BETWEEN @dtDateDebut AND @dtDateFin
			AND isnull(op.OperDate,'1900-01-01') <= P.dtDateCreationDemande 
		GROUP BY
			P.iIDBeneficiaire,
			hb.LastName + ', ' + hb.FirstName,
			Pl.PlanDesc,
			c.ConventionNo,
			hs.LastName + ', ' + hs.FirstName,
			P.dtDateCreationDemande,
			P.vcNoConfirmation,
			P.vcBourse,
			P.vcCommentaires,
			CASE 
				WHEN isnull(vcPreuveInscription,'') <> '' and isnull(vcPreuveReleve,'') <> '' then 'Relevé de note et preuve d''inscription'
				WHEN isnull(vcPreuveInscription,'') <> '' and isnull(vcPreuveReleve,'') = '' then 'Preuve d''inscription'
				WHEN isnull(vcPreuveInscription,'') = '' and isnull(vcPreuveReleve,'') <> '' then 'Relevé de note'
			END
		ORDER BY
			P.iIDBeneficiaire,
			P.dtDateCreationDemande,
			Pl.PlanDesc,
			c.ConventionNo
	*/		
END