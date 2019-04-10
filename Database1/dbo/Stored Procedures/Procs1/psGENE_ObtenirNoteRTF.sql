
/****************************************************************************************************
Code de service		:		psGENE_ObtenirNote
Nom du service		:		psGENE_ObtenirNote
But					:		Permet de lire les notes présentes dans la table tblGene_Note une à une (principalement pour la conversion RTF vers HTML)
Facette				:		GENE
Reférence			:		Notes

Parametres d'entrée :	Parametres					Description										Obligatoire
                        ----------                  ----------------								--------------                       
						@iID_Note					Identifiant de la note							Si 0, prend le premier identifiant dans la table

Exemples d'appel:
		EXECUTE [dbo].[psGENE_ObtenirNote] 0
		EXECUTE [dbo].[psGENE_ObtenirNote] 9999999

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
						tblGene_Note				iID_Note			
						tblGene_Note				tTexte
						N/A							@iStatut									= 1 si aucune erreur, -1 sinon							
						N/A							@nbRTFRestant								Nombre d'enregistrements RTF à convertir
Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-06-29					Jean-François Gauthier					Création de la procédure						
						2009-07-02					Jean-François Gauthier					Ajout du paramètre @nbRTFRestant en output
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_ObtenirNoteRTF]
	(
	@iID_Note		INT
	)
AS
	BEGIN
		SET NOCOUNT ON

		DECLARE @iStatut		INT,
				@nbRTFRestant	INT

		BEGIN TRY
			IF @iID_Note = 0	-- RETOURNE LE PREMIER ENREGISTREMENT
				BEGIN
					SET @nbRTFRestant = (SELECT COUNT(*) FROM dbo.tblGene_Note n WHERE n.tTexte like '%\rtf1\%')

					SELECT 
						TOP 1 n.iID_Note,
							  n.tTexte,
							  @nbRTFRestant AS nbRTFRestant
					FROM
						dbo.tblGene_Note n
					WHERE
						n.tTexte LIKE '%\rtf1\%'
					ORDER BY
						n.iID_Note ASC	
				END
			ELSE					-- RETOURNE L'ENREGISTREMENT SUIVANT L'IDENTIFIANT PASSÉ EN PARAMÈTRE
				BEGIN	
					IF (SELECT COUNT(*) FROM dbo.tblGene_Note WHERE iID_Note > @iID_Note) > 0
						BEGIN
							SET @nbRTFRestant = 0

							SELECT 
								TOP 1 n.iID_Note,
									  n.tTexte,
									  @nbRTFRestant AS nbRTFRestant
							FROM
								dbo.tblGene_Note n
							WHERE
								n.iID_Note > @iID_Note
								AND
								n.tTexte LIKE '%\rtf1\%'
								AND
								n.tTexte NOT LIKE '%DOCTYPE HTML%'
							ORDER BY
								n.iID_Note ASC
						END
					ELSE
						BEGIN
							SELECT 
								0 AS iID_Note,
								'' AS tTexte
						END
				END			
	
			SET @iStatut = 1
		END TRY
		BEGIN CATCH
			SET @iStatut = -1
		END CATCH

		RETURN @iStatut
	END
