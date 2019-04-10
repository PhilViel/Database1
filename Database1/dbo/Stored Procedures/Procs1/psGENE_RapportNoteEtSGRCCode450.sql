
/****************************************************************************************************
Code de service		:		psGENE_RapportNoteEtSGRCCode450
Nom du service		:		Ce service est utilisé pour générer un rapport sur les notes et SGRC pour le CODE 450
But					:		
Facette				:		GENE 
Reférence			:		Système de gestion de la relation client

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@DateDu	
						@DateAu	

Exemple d'appel:

EXEC psGENE_RapportNoteEtSGRCCode450 '2014-01-01','2014-12-31'

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------

Historique des modifications :			
						Date						Programmeur								Description							Référence
						2015-04-24					Donald Huppé							Création du service					glpi 14296
 ****************************************************************************************************/

CREATE PROCEDURE dbo.psGENE_RapportNoteEtSGRCCode450
							(	
								@DateDu	DATETIME,
								@DateAu	DATETIME
                             )
AS
	BEGIN

						--set		@DateDu	='2014-01-01'
						--set		@DateAu	='2014-01-01'

		SELECT 
			TypeNote = 'SGRC',
			IDTypeNote = t.iID_NumeroIdentifiant,
			t.dtDateCreation,
			Texte = replace(dbo.StripHTML(et.vcEtapeDescription),'&nbsp;',''),
			Client = hc.LastName +', ' + hc.FirstName,
			IDClient = t.iID_Client,
			TypeClient = CASE 
							WHEN s.SubscriberID IS NOT null THEN 'S' 
							WHEN b.BeneficiaryID IS NOT null THEN 'B' 
							ELSE 'ND'
						END,
			Qte = 1

		FROM 
			sgrc.dbo.tblSGRC_Tache t
			join (
				select miniID_Etape = min(iID_Etape),iID_Tache
				from sgrc.dbo.tblSGRC_EtapeTache GROUP by iID_Tache
				)met on met.iID_Tache = t.iID_Tache
			join sgrc.dbo.tblSGRC_EtapeTache et ON et.iID_Etape = met.miniID_Etape
			JOIN dbo.mo_human hc ON t.iID_Client = hc.humanid
			LEFT JOIN dbo.Un_Subscriber s ON  t.iID_Client = s.SubscriberID
			LEFT JOIN dbo.Un_Beneficiary b ON  t.iID_Client = b.BeneficiaryID
		where 1=1
		and t.iID_TypeTache = 27
		and LEFT(CONVERT(VARCHAR, t.dtDateCreation, 120), 10) between @DateDu and @DateAu

		UNION all

		SELECT
			TypeNote = 'Note',
			N.iID_Note,
			n.dtDateCreation,
			Texte = replace(dbo.StripHTML(n.tTexte),'&nbsp;',''),
			Client = hs.LastName +', ' + hs.FirstName,
			IDClient = n.iID_HumainClient,
			TypeClient = CASE 
							WHEN s.SubscriberID IS NOT null THEN 'S' 
							WHEN b.BeneficiaryID IS NOT null THEN 'B' 
							ELSE 'ND'
						END,
			Qte = 1

		FROM 
			tblGENE_Note N
			JOIN tblGENE_TypeNote TN ON TN.iId_TypeNote = N.iID_TypeNote
			JOIN dbo.Mo_Human hc ON N.iID_HumainCreateur = hc.HumanID
			JOIN dbo.Mo_Human hs ON N.iID_HumainClient = hs.HumanID
			LEFT JOIN dbo.Un_Subscriber s ON N.iID_HumainClient = s.SubscriberID
			LEFT JOIN dbo.Un_Beneficiary b ON N.iID_HumainClient = b.BeneficiaryID
		
		WHERE 1=1
			and n.vcTitre like '%code%450%'
			and n.iID_TypeNote <> 1 -- exclure note de tache SGRC car elle sont compté dans les tache SGRC
			and LEFT(CONVERT(VARCHAR, n.dtDateCreation, 120), 10) between @DateDu and @DateAu

END


