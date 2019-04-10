/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_InsererNote
Nom du service		: Insérer une note
But 				: Ajouter une note dans la tables des notes
Facette				: GENE
Référence			: Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				iID_HumainCreateur			Identifiant de l'humain qui a créé la note
						iID_HumainClient			Identifiant de l'humain qui est le client de la note
						iID_TypeNote				Identifiant du type de note
						cCodeTypeObjetLie			Code identifiant le type d'objet qui est lié
						iID_ObjetLie				Identifiant de l'objet lié
						vcTitre						Titre de la note
						tTexte						Texte de la note

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						tblGENE_Note				iID_Note						Identifiant de la note qui a été créée

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-03-12		Jean-Francois Arial					Création du service							
		2009-04-23		Jean-François Gauthier				Modification pour rendre @cCodeTypeObjetLie 
															soit optionnel
		2009-04-30		Jean-François Gauthier				Ajout du paramètre @cCodeTypeNote 
															(nécessaire car parfois @iID_TypeNote ne sera
															 fourni)
		2009-05-01		Jean-François Gauthier				Ajout de la gestion d'erreur
		2009-09-24		Jean-François Gauthier				Remplacement du @@Identity par Scope_Identity()
		2016-05-26      Steeve Picard                       Conversion du RaisError standard
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_InsererNote]
	@iID_HumainCreateur			INTEGER,
	@iID_HumainClient			INTEGER,
	@iID_TypeNote				INTEGER			= NULL,
	@cCodeTypeObjetLie			VARCHAR(10)		= NULL,
	@iID_ObjetLie				INTEGER,
	@vcTitre					VARCHAR(250),
	@tTexte						TEXT,
	@vcTexteLienObjetLie		VARCHAR(250)	= NULL,
	@cCodeTypeNote				VARCHAR(10)		= NULL
AS
BEGIN
	SET NOCOUNT ON	

	DECLARE @iID_TypeObjet INT
													
	DECLARE		 @iErrno				INTEGER
				,@iErrSeverity			INTEGER
				,@iErrState				INTEGER
				,@vErrmsg				VARCHAR(1024)
				,@iStatut				INTEGER		-- SI > 0, OPÉRATION EFFECTUÉE SANS ERREUR

	BEGIN TRY		
			IF @cCodeTypeObjetLie IS NOT NULL
				BEGIN
					SELECT 
						@iID_TypeObjet = iID_TypeObjet
					FROM 
						dbo.tblGENE_TypeObjet
					WHERE 
						cCodeTypeObjet = @cCodeTypeObjetLie
				END
		
			-- DANS CERTAINS CAS, LE ID SERA NULL, À CE MOMENT, ON UTILISERA @cCodeTypeNote
			IF  @iID_TypeNote IS NOT NULL
				BEGIN
					INSERT INTO dbo.tblGene_Note 
						(
						dtDateCreation, 
						iID_HumainCreateur, 
						iID_HumainClient, 
						iID_TypeNote, 
						iID_TypeObjet, 
						vcTexteLienObjetLie, 
						iID_ObjetLie, 
						vcTitre, 
						tTexte, 
						dtDateModification, 
						iID_HumainModifiant
						)
					VALUES 
						(
						GETDATE(), 
						@iID_HumainCreateur, 
						@iID_HumainClient, 
						@iID_TypeNote, 
						@iID_TypeObjet, 
						@vcTexteLienObjetLie, 
						@iID_ObjetLie, 
						@vcTitre, 
						@tTexte, 
						GETDATE(), 
						@iID_HumainCreateur
						)

					SELECT	@iStatut = SCOPE_IDENTITY()	
				END
			ELSE
				BEGIN
					INSERT INTO dbo.tblGene_Note 
						(
						dtDateCreation, 
						iID_HumainCreateur, 
						iID_HumainClient, 
						iID_TypeNote, 
						iID_TypeObjet, 
						vcTexteLienObjetLie, 
						iID_ObjetLie, 
						vcTitre, 
						tTexte, 
						dtDateModification, 
						iID_HumainModifiant
						)
					SELECT
						GETDATE(), 
						@iID_HumainCreateur, 
						@iID_HumainClient, 
						tn.iId_TypeNote, 
						@iID_TypeObjet, 
						@vcTexteLienObjetLie, 
						@iID_ObjetLie, 
						@vcTitre, 
						@tTexte, 
						GETDATE(), 
						@iID_HumainCreateur
					FROM
						dbo.tblGENE_TypeNote tn
					WHERE
						tn.cCodeTypeNote = @cCodeTypeNote	

					SELECT	@iStatut = SCOPE_IDENTITY()	
				END						
	END TRY
	BEGIN CATCH
		SELECT									
			@vErrmsg		= REPLACE(ERROR_MESSAGE(),'%',' '),
			@iErrState		= ERROR_STATE(),
			@iErrSeverity	= ERROR_SEVERITY(),
			@iErrno			= ERROR_NUMBER();

			IF @iErrno >= 50000					
				BEGIN
					RAISERROR ('INSERTION NOTE EN ERREUR', 10, 1)
				END
			ELSE								
				BEGIN
					SET @vErrmsg = CAST(@iErrno AS VARCHAR(6)) + ' : ' + @vErrmsg 
					RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState)
				END
		SET @iStatut = -1
	END CATCH
		
	RETURN @iStatut
END
