
/****************************************************************************************************
Code de service		:		fntGENE_RechercherEquipes
Nom du service		:		Rechercher des équipes de travail 
But					:		Rechercher les équipes répondant à certain critères
Facette				:		GENE
Reférence			:		SGRC

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@iId_Humain					Critère de recherche : Identifiant de l’humain dont on souhaite récupérer les équipes
						@iId_Equipe				Critère de recherche : Identifiant de l’équipe à renvoyer
						@iId_HumainResponsable		Critère de recherche : Identifiant de l’humain dont on cherche les équipes sous sa responsabilité

Exemple d'appel:
                
                SELECT * FROM fntGENE_RechercherEquipes(1, null, null)
				SELECT * FROM [fntGENE_RechercherEquipes](NULL, NULL,546654)

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------
                        tblGENE_EquipeTravail		Tous les champs	                            Tous les champs de la table tblGENE_Note
						MoHuman						FirstName									Prénom de l’humain responsable de l’équipe
						MoHuman						LastName									Nom de l’humain responsable de l’équipe
                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-03-19					Jean-Francois Arial						Création de la fonction           
						2009-06-15					Jean-François Gauthier					Ajout du ORDER BY
 ****************************************************************************************************/

CREATE FUNCTION dbo.fntGENE_RechercherEquipes
				(
					@iId_Humain INT,
					@iId_Equipe INT,
					@iId_HumainResponsable INT

				)
RETURNS 
@tblEquipe TABLE (
	[iID_Equipe] [int] NULL,
	[vcNomEquipe] [varchar](50) NULL,
	[vcDescription] [varchar](100) NULL,
	[iID_HumainResponsable] [int] NULL,
	[iID_EquipeResponsable] [int] NULL,
	[LastName] [varchar](50) NULL,
	[FirstName][varchar](50) NULL,
	[vcNomResponsable] [varchar](100) NULL)
		
AS
BEGIN

	IF (@iId_Equipe IS NOT NULL)
	BEGIN
		INSERT INTO @tblEquipe
		SELECT 
				ET.[iID_Equipe],
				[vcNomEquipe],
				[vcDesciption],
				[iID_HumainResponsable],
				[iID_EquipeResponsable],
				H.LastName, 
				H.FirstName,
				H.LastName + ', ' +	H.FirstName
		FROM 
			dbo.tblGENE_EquipeTravail ET 
			INNER JOIN dbo.Mo_Human H 
				ON (H.HumanID = ET.iID_HumainResponsable)
		WHERE 
			ET.iID_Equipe = @iId_Equipe
		ORDER BY
			[vcNomEquipe]
	END
	ELSE
	BEGIN 
		IF (@iId_HumainResponsable IS NOT NULL)
		BEGIN
			INSERT INTO @tblEquipe
			SELECT ET.[iID_Equipe],
					[vcNomEquipe],
					[vcDesciption],
					[iID_HumainResponsable],
					[iID_EquipeResponsable],
					H.LastName, 
					H.FirstName,
					H.LastName + ', ' +	H.FirstName
			FROM 
				dbo.tblGENE_EquipeTravail ET 
				INNER JOIN dbo.Mo_Human H 
					ON (H.HumanID = ET.iID_HumainResponsable)
			WHERE 
				ET.iID_HumainResponsable = @iId_HumainResponsable
			ORDER BY
				[vcNomEquipe]
		END
		ELSE
		BEGIN
			INSERT INTO @tblEquipe
			SELECT ET.[iID_Equipe],
					[vcNomEquipe],
					[vcDesciption],
					[iID_HumainResponsable],
					[iID_EquipeResponsable],
					H.LastName, 
					H.FirstName,
					H.LastName + ', ' +	H.FirstName
			FROM 
				dbo.tblGENE_EquipeTravail ET 
				INNER JOIN tblGENE_LienHumainEquipe LHE 
					ON (ET.iID_Equipe = LHE.iID_Equipe)
				INNER JOIN dbo.Mo_Human H 
					ON (H.HumanID = LHE.iID_Humain)
			WHERE LHE.iID_Humain = @iId_Humain
			ORDER BY
				[vcNomEquipe]
		END
	END
	RETURN

END


