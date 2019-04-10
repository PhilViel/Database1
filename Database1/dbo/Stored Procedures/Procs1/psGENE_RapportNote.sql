
/****************************************************************************************************
Code de service		:		psGENE_RapportNote
Nom du service		:		Ce service est utilisé pour générer un rapport sur les notes
But					:		
Facette				:		GENE 
Reférence			:		Système de gestion de la relation client

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@dtDateCreationDe			Date de création de la note
						@dtDateCreationA			Date de création de la note
						@iID_TypeNote				id Type de note
						@iID_TitreNote				Id du titre de la note
						@vcTexteTitreNote			Texte du titre de la note
						@vcTexteNote				Texte de la note
						@iID_HumainCreateur			Id du user qui a créé la note

Exemple d'appel:

EXEC psGENE_RapportNote
								@dtDateCreationDe = '2016-01-01',
								@dtDateCreationA = '2016-12-21',
								@iID_TypeNote = 0,
								@iID_TitreNote = NULL, --25
								@vcTexteTitreNote = NULL,
								@vcTexteNote = NULL,
								@iID_HumainCreateur	 = 763145,
								@iID_Equipe = 2,
								@RepID = NULL

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       tblGENE_TypeNote	            Tous

Historique des modifications :			
						Date						Programmeur								Description							Référence
						2012-02-10					Donald Huppé							Création du service
						2012-04-17					Donald Huppé							compléter la demande originale : ajouter les tâche SGRC (après le UNION)
						2013-03-13					Donald Huppé							Ajout de la fonction StripHTML pour enlever les caractères HTML dans le texte
						2013-03-22					Donald Huppé							glpi 9335 - ajout du critère de recherche par RepID du groupe d'unité
						2013-04-17					Donald Huppé							Dans les note SGRC P: On vérifie qu'on n'a pas demandé de recherche pour un type de note car il n'y a pas de type dans SGRC.
						2016-07-27					Donald Huppé							Ajouter clause 1=1 dans le select sur les SGRC. ça fait aboutir le rapport quand on ne sélectionne pas de type de note. 
																							Je ne comprend pas pourquoi ça marche, c'était un simple test, mais ça marche.
						2017-05-25					Donald Huppé							Le paramètre @iID_Equipe n'est plus appelé par le rapport alors on met la valeur par défaut = 0
																							Comme les équipes de travail étaient utilisées par le SGRC qui n'est plus utilisé, les équipes n'étaitent plus à jour.
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_RapportNote]
							(	
								@dtDateCreationDe	DATETIME,
								@dtDateCreationA	DATETIME,
								@iID_TypeNote		INT,
								@iID_TitreNote		INT,
								@vcTexteTitreNote	VARCHAR(250),
								@vcTexteNote		VARCHAR(500),
								@iID_HumainCreateur	INT,
								@iID_Equipe			INT = 0,
								@RepID				int = NULL
                             )
AS
	BEGIN
		SET NOCOUNT ON
		SET ARITHABORT ON
				
	DECLARE @vcTitreNote VARCHAR(250) 

	SET @vcTitreNote = NULL

	SELECT @vcTitreNote = vcTitreNote
	FROM tblGENE_TitreNote
	WHERE iID_TitreNote = @iID_TitreNote
	
	IF ISNULL(@vcTexteTitreNote,'') <> ''
	SET @vcTitreNote = '%' + LTRIM(RTRIM(@vcTexteTitreNote)) + '%'

	SET @vcTexteNote = '%' + ISNULL(@vcTexteNote,'') + '%'

	create table #HumainEquipe (iID_Humain int)

	IF @iID_Equipe <> 0 
	BEGIN
		INSERT INTO #HumainEquipe
		SELECT 
			iID_Humain 
		FROM 
			tblGENE_EquipeTravail e
			JOIN tblGENE_LienHumainEquipe l ON e.iID_Equipe = l.iID_Equipe
		WHERE 
			e.iID_Equipe = @iID_Equipe
	end

	SELECT top 10000
		iID_Note,
		--tTexte = substring(tTexte,1,32766),
		tTexte = replace(dbo.StripHTML(tTexte),'&nbsp;',''),
		vcTitre,
		dtDateCreation,
		tNoteTypeDesc,
		Createur,
		IDClient,
		TypeClient,
		Client

	FROM (

		-- Les notes
		SELECT top 10000
			N.iID_Note,
			n.tTexte,
			n.vcTitre,
			n.dtDateCreation,
			TN.tNoteTypeDesc,
			Createur = hc.LastName + ', ' + hc.FirstName,
			IDClient = n.iID_HumainClient,
			TypeClient = CASE 
							WHEN s.SubscriberID IS NOT null THEN 'Souscripteur' 
							WHEN b.BeneficiaryID IS NOT null THEN 'Bénéficiaire' 
							ELSE 'ND'
						END,
			Client = hs.LastName +', ' + hs.FirstName
			
		FROM 
			tblGENE_Note N
			JOIN tblGENE_TypeNote TN ON TN.iId_TypeNote = N.iID_TypeNote
			JOIN dbo.Mo_Human hc ON N.iID_HumainCreateur = hc.HumanID
			JOIN dbo.Mo_Human hs ON N.iID_HumainClient = hs.HumanID
			LEFT JOIN dbo.Un_Subscriber s ON N.iID_HumainClient = s.SubscriberID
			LEFT JOIN dbo.Un_Beneficiary b ON N.iID_HumainClient = b.BeneficiaryID
			
			LEFT JOIN (
						SELECT c1.subscriberID
						FROM dbo.Un_Convention c1
						JOIN dbo.Un_Unit u1 ON c1.ConventionID = u1.ConventionID
						WHERE 
							-- si un rep est demandé, alors on sort les données
							u1.RepID = @RepID
							-- si aucun repid est demandé, alors on sort rien (1=0)
							or (@RepID IS NULL and 1=0)
						GROUP by c1.subscriberID
						) rr ON s.SubscriberID = rr.SubscriberID

		WHERE 
			(LEFT(CONVERT(VARCHAR, dtDateCreation, 120), 10) BETWEEN @dtDateCreationDe AND @dtDateCreationA OR @dtDateCreationDe IS NULL)
			AND (iID_HumainCreateur = @iID_HumainCreateur OR @iID_HumainCreateur = 0)
			AND (n.iID_TypeNote = @iID_TypeNote OR @iID_TypeNote = 0)
			AND (vcTitre like @vcTitreNote OR @vcTitreNote IS NULL)
			AND (tTexte LIKE @vcTexteNote or @vcTexteNote IS NULL)
			AND (N.iID_HumainCreateur IN (SELECT iID_Humain FROM #HumainEquipe) OR @iID_Equipe = 0)
			AND (
				(RR.SubscriberID IS not NULL AND @RepID IS NOT NULL) 
				OR @RepID IS NULL
				)
			
		UNION all
			
		-- Les étapes de tâche SGRC
		SELECT TOP 10000
			iID_Note = et.iID_Etape,
			tTexte = et.vcEtapeDescription,
			et.vcTitre,
			dtDateCreation = et.dtDateEtape,
			tNoteTypeDesc = 'Étape de tâche no ' + cast(t.iID_Tache AS varchar(10)),
			Createur = ht.LastName + ', ' + ht.FirstName,
			IDClient = t.iID_Client,
			TypeClient = CASE 
							WHEN s.SubscriberID IS NOT null THEN 'Souscripteur' 
							WHEN b.BeneficiaryID IS NOT null THEN 'Bénéficiaire' 
							ELSE 'ND'
						END,
			Client = hc.LastName +', ' + hc.FirstName
			
		FROM 
			sgrc.dbo.tblSGRC_Tache t
			join sgrc.dbo.tblSGRC_EtapeTache et ON t.iID_Tache = et.iID_Tache
			JOIN dbo.Mo_Human ht ON et.iID_HumainModifiant = ht.HumanID
			JOIN dbo.mo_human hc ON t.iID_Client = hc.humanid
			LEFT JOIN dbo.Un_Subscriber s ON  t.iID_Client = s.SubscriberID
			LEFT JOIN dbo.Un_Beneficiary b ON  t.iID_Client = b.BeneficiaryID
			/*
			LEFT JOIN (
						SELECT c1.subscriberID
						FROM dbo.Un_Convention c1
						JOIN dbo.Un_Unit u1 ON c1.ConventionID = u1.ConventionID
						WHERE 
							u1.RepID = @RepID
							or (@RepID IS NULL and 1=0)
						GROUP by c1.subscriberID
						) rr ON s.SubscriberID = rr.SubscriberID
						*/
		WHERE 
				1=1 -- 2016-07-27
				AND @iID_TypeNote = 0 -- On vérifie qu'on n'a pas demandé de recherche pour un type de note car il n'y a pas de type dans SGRC.
				and (LEFT(CONVERT(VARCHAR, et.dtDateEtape, 120), 10) BETWEEN @dtDateCreationDe AND @dtDateCreationA OR @dtDateCreationDe IS NULL)
				AND (et.iID_HumainModifiant = @iID_HumainCreateur OR @iID_HumainCreateur = 0)
				AND (et.vcTitre like @vcTitreNote OR @vcTitreNote IS NULL)
				AND (et.vcEtapeDescription LIKE @vcTexteNote or @vcTexteNote IS NULL)
				AND (et.iID_HumainModifiant IN (SELECT iID_Humain FROM #HumainEquipe) OR @iID_Equipe = 0)
				and @RepID IS NULL 
				
		) V
		
	ORDER BY
		IDClient asc,
		dtDateCreation desc
		
	SET ARITHABORT OFF

	END
	
	/*

EXEC psGENE_RapportNote
								@dtDateCreationDe = '2015-07-27',
								@dtDateCreationA = '2015-07-27',
								@iID_TypeNote = 4,
								@iID_TitreNote = 32, --25
								@vcTexteTitreNote = NULL,
								@vcTexteNote = NULL,
								@iID_HumainCreateur	 = 584160,
								@iID_Equipe = 0,
								@RepID = NULL
								*/
		

