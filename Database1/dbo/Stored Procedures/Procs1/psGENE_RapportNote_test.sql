
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

EXEC psGENE_RapportNote_test
								@dtDateCreationDe = '2012-01-01',
								@dtDateCreationA = '2012-12-21',
								@iID_TypeNote = 0,
								@iID_TitreNote = 0, --25
								@vcTexteTitreNote = NULL,
								@vcTexteNote = 'illustration',
								@iID_HumainCreateur	 = 0,
								@iID_Equipe = 0

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       tblGENE_TypeNote	            Tous

Historique des modifications :			
						Date						Programmeur								Description							Référence
						2012-02-10					Donald Huppé							Création du service
						2012-04-17					Donald Huppé							compléter la demande originale : ajouter les tâche SGRC (après le UNION)
 ****************************************************************************************************/

CREATE PROCEDURE dbo.psGENE_RapportNote_test
							(	
								@dtDateCreationDe	DATETIME,
								@dtDateCreationA	DATETIME,
								@iID_TypeNote		INT,
								@iID_TitreNote		INT,
								@vcTexteTitreNote	VARCHAR(250),
								@vcTexteNote		VARCHAR(500),
								@iID_HumainCreateur	INT,
								@iID_Equipe			INT
                             )
AS
	BEGIN
		SET NOCOUNT ON
		
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
		--tTexteori = substring(tTexte,1,32766),
		tTexte = replace(dbo.StripHTML(substring(tTexte,1,32766)),'&nbsp;',''),
		--tTexte2 = dbo.StripHTML(tTexte),
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
			left JOIN dbo.Un_Subscriber s ON N.iID_HumainClient = s.SubscriberID
			LEFT JOIN dbo.Un_Beneficiary b ON N.iID_HumainClient = b.BeneficiaryID
		WHERE 
			(LEFT(CONVERT(VARCHAR, dtDateCreation, 120), 10) BETWEEN @dtDateCreationDe AND @dtDateCreationA OR @dtDateCreationDe IS NULL)
			AND (iID_HumainCreateur = @iID_HumainCreateur OR @iID_HumainCreateur = 0)
			AND (n.iID_TypeNote = @iID_TypeNote OR @iID_TypeNote = 0)
			AND (vcTitre like @vcTitreNote OR @vcTitreNote IS NULL)
			AND (tTexte LIKE @vcTexteNote or @vcTexteNote IS NULL)
			AND (N.iID_HumainCreateur IN (SELECT iID_Humain FROM #HumainEquipe) OR @iID_Equipe = 0)
			--AND iid_Note = 180986
			
		UNION all
			
		-- Les étapes de tâche SGRC
		SELECT 
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
			left JOIN dbo.Un_Subscriber s ON  t.iID_Client = s.SubscriberID
			LEFT JOIN dbo.Un_Beneficiary b ON  t.iID_Client = b.BeneficiaryID

		WHERE 
			(LEFT(CONVERT(VARCHAR, et.dtDateEtape, 120), 10) BETWEEN @dtDateCreationDe AND @dtDateCreationA OR @dtDateCreationDe IS NULL)
			AND (et.iID_HumainModifiant = @iID_HumainCreateur OR @iID_HumainCreateur = 0)
			--AND (n.iID_TypeNote = @iID_TypeNote OR @iID_TypeNote = 0) -- On ne fait pas de recherche par type dans le SGRC
			AND (et.vcTitre like @vcTitreNote OR @vcTitreNote IS NULL)
			AND (et.vcEtapeDescription LIKE @vcTexteNote or @vcTexteNote IS NULL)
			AND (et.iID_HumainModifiant IN (SELECT iID_Humain FROM #HumainEquipe) OR @iID_Equipe = 0)
		) V
		
	ORDER BY
		IDClient asc,
		dtDateCreation desc
		
	END
	
	/*
EXEC psGENE_RapportNote
								@dtDateCreationDe = '1950-02-01',
								@dtDateCreationA = '2012-02-01',
								@iID_TypeNote = 0,
								@iID_TitreNote = 0, --25
								@vcTexteTitreNote = NULL,
								@vcTexteNote = NULL,
								@iID_HumainCreateur	 = 0
		*/
		

