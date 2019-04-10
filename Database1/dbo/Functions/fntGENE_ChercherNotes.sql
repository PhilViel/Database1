
/****************************************************************************************************
Code de service		:		fntGENE_ChercherNotes
Nom du service		:		Rechercher des notes
But					:		Rechercher les notes répondant à certain critères
Facette				:		GENE
Reférence			:		Système de gestion des notes

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@iID_Note					Critère de recherche : Identifiant de la Note
						@vcTitre					Critère de recherche : Titre
						@dtDateDebut				Critère de recherche : Date de début des notes
						@dtDateFin					Critère de recherche : Date de fin des notes
						@iID_HumainClient			Critère de recherche : Identifiant de l’humain client de la note
						@iID_HumainCreateur			Critère de recherche : Identifiant de l’humain créateur de la note dont on souhaite récupérer les équipes
						@iID_TypeNote               Critère de recherche : Identifiant du type de note
						@vcListeCodeTypeNote		Critère de recherche : Liste de codes de types de notes (ignoré si @iID_TypeNote est précisé)

Exemple d'appel:
                SELECT top 20 * FROM fntGENE_ChercherNotes(null, null, null, null, null, null, null, 'GENE_VISUALISER_NOTE')
                
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------
                        tblGENE_Note				Tous les champs	                            Tous les champs de la table tblGENE_Note
						Mo_Human					FirstName + LastName						Le nom et prénom de l'humain créateur
						tblGENE_TypeObjet			vcUrlAccess									Lien vers l'objet qui est lié à la note
						Mo_Adr						Email										Adresse email de l'humain créateur
						tblGENE_TypeNote			cCodeTypeNote								Code du type de note
						tblGENE_TypeNote			tNoteTypeDesc								Description du type de note

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-03-12					Jean-Francois Arial						Création de la fonction           
						2009-04-23					Jean-François Gauthier					Correction la condition
																							AND iID_HumainCreateur	=	ISNULL(@iID_HumainClient,iID_HumainCreateur)
																							la variable à utilser est @iID_HumainCreateur
						2009-05-08					Jean-François Gauthier					Formatage
						2009-07-02					Jean-François Gauthier					Ajout du paramètre vcListeCodeTypeNote					
						2009-07-03					Jean-François Gauthier					Ajout du champ cCodeTypeNote dans la table des valeurs de sortie
						2009-07-06					Jean-François Gauthier					Augmentation de la dimension du champ [cCodeTypeNote] à 75 caractères
						2009-07-14					Jean-François Gauthier					Ajout du champ tn.tNoteTypeDesc
						2010-05-20					Jean-François Gauthier					Ajout du left join sur la table des adresses
																							car celle-ci n'est pas obligatoire
						2010-07-22					Jean-François Gauthier					Modification afin d'aller chercher la valeur de vcUrlAcces dans les
																							paramètres applicatifs																							
 ****************************************************************************************************/
CREATE FUNCTION [dbo].[fntGENE_ChercherNotes]
				(
					@iID_Note				INT,
					@vcTitre				VARCHAR(250),
					@dtDateDebut			DATETIME,
					@dtDateFin				DATETIME,
					@iID_HumainClient		INT,
					@iID_HumainCreateur		INT,
					@iID_TypeNote			INT,
					@vcListeCodeTypeNote	VARCHAR(1000)			
				)
RETURNS 
@tblNotes TABLE (
					iID_Note			INT,
					vcTitre				VARCHAR(250),
					tTexte				TEXT,
					iID_TypeNote		INT,
					dtDateCreation		DATETIME,
					iID_HumainClient	INT,
					iID_HumainCreateur	INT,
					iID_HumainModifiant INT,
					dtDateModification	DATETIME,
					iID_ObjetApplication INT,
					iID_TypeObjet		INT,
					vcTexteLienObjetLie VARCHAR(250),
					vcHumainCreateur	VARCHAR(250),
					vcUrlAccess			VARCHAR(250),
					vcEmail				VARCHAR(100),
					cCodeTypeNote		VARCHAR(75),
					tNoteTypeDesc		TEXT
				)
AS
BEGIN
	DECLARE @vcUrlAccess VARCHAR(250)
	
	IF NOT(dbo.fnGENE_ObtenirParametre('NOTES_SGRC_URL_ACCES', NULL, NULL, NULL, NULL, NULL, NULL) < '0')
		BEGIN
			SET @vcUrlAccess = dbo.fnGENE_ObtenirParametre('NOTES_SGRC_URL_ACCES', NULL, NULL, NULL, NULL, NULL, NULL)
		END
	ELSE
		BEGIN 
			SET @vcUrlAccess = NULL
		END
	
	IF ((@iID_Note IS NOT NULL) OR (@vcTitre IS NOT NULL) OR (@dtDateDebut IS NOT NULL) 
		OR (@dtDateFin IS NOT NULL) OR (@iID_HumainClient IS NOT NULL) 
		OR (@iID_HumainCreateur IS NOT NULL) OR (@iID_TypeNote IS NOT NULL) OR @vcListeCodeTypeNote IS NOT NULL)
	BEGIN
			
		IF @iID_TypeNote IS NOT NULL
			BEGIN
				INSERT INTO @tblNotes
				SELECT 
					N.[iID_Note]
					,N.[vcTitre]
					,N.[tTexte]
					,N.[iID_TypeNote]
					,N.[dtDateCreation]
					,N.[iID_HumainClient]
					,N.[iID_HumainCreateur]
					,N.[iID_HumainModifiant]
					,N.[dtDateModification]
					,N.[iID_ObjetLie]
					,N.[iID_TypeObjet]
					,N.[vcTexteLienObjetLie]
					,H.[FirstName] + H.[LastName]
					,@vcUrlAccess AS vcUrlAccess
					--,TObj.[vcUrlAccess]
					,A.[EMail]
					,tn.cCodeTypeNote
					,tn.tNoteTypeDesc
				FROM 
					dbo.tblGENE_Note N
					INNER JOIN dbo.tblGENE_TypeNote	tn 
						ON (tn.iID_TypeNote = N.iId_TypeNote)
					INNER JOIN dbo.Mo_Human H 
						ON (N.iID_HumainCreateur = H.HumanId)
					LEFT JOIN dbo.Mo_Adr A							-- 2010-05-20 : JFG : Ajout du Left join
						ON (H.AdrID = A.AdrID)
					--LEFT JOIN dbo.tblGENE_TypeObjet TObj 
					--	ON (TObj.iID_TypeObjet = N.iID_TypeObjet)
				WHERE 
					N.iID_Note = ISNULL(@iID_Note, N.iID_Note) 
					AND N.vcTitre = ISNULL(@vcTitre, N.vcTitre)
					AND N.dtDateCreation >= ISNULL(@dtDateDebut, N.dtDateCreation)
					AND N.dtDateCreation <= ISNULL(@dtDateFin, N.dtDateCreation)
					AND N.iID_HumainClient = ISNULL(@iID_HumainClient, N.iID_HumainClient)
					AND N.iID_HumainCreateur = ISNULL(@iID_HumainCreateur, N.iID_HumainCreateur)
					AND 
					(
						N.iID_TypeNote = ISNULL(@iID_TypeNote, N.iID_TypeNote)
					)
				ORDER BY
					N.dtDateCreation DESC 
		END
	ELSE
		BEGIN
			INSERT INTO @tblNotes
			SELECT 
				N.[iID_Note]
				,N.[vcTitre]
				,N.[tTexte]
				,N.[iID_TypeNote]
				,N.[dtDateCreation]
				,N.[iID_HumainClient]
				,N.[iID_HumainCreateur]
				,N.[iID_HumainModifiant]
				,N.[dtDateModification]
				,N.[iID_ObjetLie]
				,N.[iID_TypeObjet]
				,N.[vcTexteLienObjetLie]
				,H.[FirstName] + H.[LastName]
				,@vcUrlAccess AS vcUrlAccess
				--,TObj.[vcUrlAccess]
				,A.[EMail]
				,tn.cCodeTypeNote
				,tn.tNoteTypeDesc
			FROM 
				dbo.tblGENE_Note N
				INNER JOIN dbo.tblGENE_TypeNote	tn 
					ON (tn.iID_TypeNote = N.iId_TypeNote)
				INNER JOIN dbo.Mo_Human H 
					ON (N.iID_HumainCreateur = H.HumanId)
				LEFT JOIN dbo.Mo_Adr A							-- 2010-05-20 : JFG : Ajout du Left join
					ON (H.AdrID = A.AdrID)
				--LEFT JOIN dbo.tblGENE_TypeObjet TObj 
				--	ON (TObj.iID_TypeObjet = N.iID_TypeObjet)
			WHERE 
				N.iID_Note = ISNULL(@iID_Note, N.iID_Note) 
				AND N.vcTitre = ISNULL(@vcTitre, N.vcTitre)
				AND N.dtDateCreation >= ISNULL(@dtDateDebut, N.dtDateCreation)
				AND N.dtDateCreation <= ISNULL(@dtDateFin, N.dtDateCreation)
				AND N.iID_HumainClient = ISNULL(@iID_HumainClient, N.iID_HumainClient)
				AND N.iID_HumainCreateur = ISNULL(@iID_HumainCreateur, N.iID_HumainCreateur)
				AND tn.cCodeTypeNote IN (SELECT strField FROM dbo.fntGENE_SplitIntoTable(@vcListeCodeTypeNote,','))
			ORDER BY
				N.dtDateCreation DESC 
		END
	END
	ELSE
		INSERT INTO @tblNotes
		SELECT NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	RETURN
END


