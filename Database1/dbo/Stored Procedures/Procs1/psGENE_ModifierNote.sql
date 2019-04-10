/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_ModifierNote
Nom du service		: Modifier une note
But 				: Modifier une note dans la tables des notes
Facette				: GENE
Référence			: Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Note					Identifiant de la note
						iID_TypeNote				Identifiant du type de note
						dtDateCreation				Date de la note
						iID_HumainClient			Identifiant de l'humain qui est le client de la note
						iID_HumainCreateur			Identifiant de l'humain qui a créé la note
						dtDateModification			Date de la modification
						iID_HumainModifiant			Identifiant de l'humain qui modifie la note
						tTexte						Texte de la note

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						N/A							@iStatut						>0, CELA A FONCTIONNÉ

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-03-12		Jean-Francois Arial					Création du service							
		2009-07-21		Jean-François Gauthier				Ajout de la valeur de retour
		2009-07-23		Jean-François Gauthier				Modification sur la façon de retourner @iStatut
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ModifierNote]
	@iID_Note					INT,	
	@iID_TypeNote				INT,
	@dtDateCreation				DATETIME,
	@iID_HumainClient			INT,
	@iID_HumainCreateur			INT,
	@dtDateModification			DATETIME,
	@iID_HumainModifiant		INT,
	@tTexte						TEXT,
	@vcTitre					VARCHAR(250)	
AS
BEGIN
	DECLARE @dtDateDernModif DATETIME	-- Sert à stocké la dernière date de modification de l'étape
	DECLARE @iStatut		 INT		-- Variable de retour de la procédure

	--Valider les données en paramètres
	SET @iStatut = 0
	IF @iID_Note IS NOT NULL AND @dtDateModification IS NOT NULL
		BEGIN
			--Validation de la concurence
			SELECT @dtDateDernModif = dtDateModification
			FROM tblGENE_Note
			WHERE iID_Note = @iID_Note
		 
			IF @dtDateDernModif = @dtDateModification
				BEGIN
					UPDATE dbo.tblGENE_Note
					SET iID_TypeNote = @iID_TypeNote,
						dtDateCreation = @dtDateCreation,
						iID_HumainClient = @iID_HumainClient,
						iID_HumainCreateur = @iID_HumainCreateur,
						dtDateModification = GETDATE(),
						iID_HumainModifiant = @iID_HumainModifiant,
						tTexte = @tTexte,
						vcTitre = @vcTitre		
					WHERE @iID_Note = iID_Note

					SET @iStatut = 1
				END
		END
	RETURN @iStatut
END
