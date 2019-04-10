/****************************************************************************************************
Code de service		:		fntGENE_ObtenirMembreEquipe
Nom du service		:		Ce service est utilisé pour récupérer les membres d’une équipe
But					:		Récupérer les membres d’une équipe 
Facette				:		GENE
Reférence			:		SGRC

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@iId_Equipe				Critère de recherche : Identifiant de l’équipe à renvoyer
						@iId_HumainResponsable	Critère de recherche : Identifiant de l’humain responsable de l'équipe

Exemple d'appel:
                
                SELECT * FROM fntGENE_ObtenirMembreEquipe(1,NULL)

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------
                        MoHuman						HumanID										Identifiant de l'humain
						MoHuman						FirstName									Prénom de l’humain 
						MoHuman						LastName									Nom de l’humain 
                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-03-23					Jean-Francois Arial						Création de la fonction           
						2009-06-15					Jean-François Gauthier					Ajout du ORDER BY
 ****************************************************************************************************/
CREATE FUNCTION dbo.fntGENE_ObtenirMembreEquipe
				(					
					@iId_Equipe INT = NULL,
					@iId_HumainResponsable INT = NULL
				)
RETURNS 
@tblMembre TABLE (
	[HumanID] [int], 
	[HumainName] [varchar](100),
	[LastName] [varchar](100),
	[FirstName] [varchar](100)
	)
	
AS
BEGIN

	IF (@iId_Equipe IS NOT NULL)
	BEGIN
		INSERT INTO @tblMembre
		SELECT [HumanID],
				[LastName] + ', ' + [FirstName],				
				[LastName],
				[FirstName]
		FROM tblGENE_LienHumainEquipe LHE
		JOIN dbo.Mo_Human H ON (H.HumanID = LHE.iID_Humain)
		WHERE 
			LHE.iID_Equipe = @iId_Equipe
		ORDER BY
				[LastName] + ', ' + [FirstName]
	END
	ELSE
	BEGIN 
		IF (@iId_HumainResponsable IS NOT NULL)
		BEGIN
			INSERT INTO @tblMembre
			SELECT [HumanID],
					[LastName] + ', ' + [FirstName],
					[LastName],
					[FirstName]			
			FROM tblGENE_EquipeTravail ET
			JOIN tblGENE_LienHumainEquipe LHE ON (ET.iID_Equipe = LHE.iID_Equipe)
			JOIN dbo.Mo_Human H ON (H.HumanID = LHE.iID_Humain)
			WHERE 
				ET.iID_HumainResponsable = @iId_HumainResponsable
			ORDER BY
				[LastName] + ', ' + [FirstName]
					
		END
		ELSE
		BEGIN
			INSERT INTO @tblMembre
			SELECT NULL,NULL, NULL, NULL
		END
	END
	RETURN
END


