/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fntIQEE_ModifierNom
Nom du service		: Modifier un nom de l’IQÉÉ
But 				: Modifier un prénom ou nom de l’IQÉÉ au niveau du jeu de caractères avant qu'il soit validé.  Les
					  caractères latino avec accents sont remplacé par des caractères sans accent et certains autres
					  caractères sont retirés.
Facette				: IQEE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				vcNom						Nom ou prénom.

Exemple d’appel		:	SELECT * FROM [dbo].[fntIQEE_ModifierNom]('Brick:Abárakõã::¸()`0123456789')

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							vcNom							Nom modifié
						S/O							vcCaracteres_Modifies		    Caractères modifiés ou retirés par
																					la procédure.

Historique des modifications :
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2010-02-12		Éric Deshaies						Création du service
		2010-09-05		Éric Deshaies						Ajout de caractères à supprimer

****************************************************************************************************/
CREATE FUNCTION [dbo].[fntIQEE_ModifierNom]
(
	@vcNom VARCHAR(20)
)
RETURNS @tblIQEE_Nom TABLE
(
	vcNom VARCHAR(20) NULL,
	vcCaracteres_Modifies VARCHAR(20) NULL
)
AS
BEGIN
	-- Initialisations
	DECLARE
		@vcCaracteres_Modifies VARCHAR(40),
		@vcCaracteres_Remplacement VARCHAR(200),
		@vcCaracteres_Suppression VARCHAR(200),
		@iCompteur INT

	IF @vcNom IS NOT NULL
		BEGIN
			-- Déterminer les caractères à remplacer et à supprimer
			SET @vcCaracteres_Remplacement = 'õoãaáa'
			SET @vcCaracteres_Suppression = ':¸()`0123456789'
			SET @vcCaracteres_Modifies = ''

			-- Remplacer les caractères
			SET @iCompteur = 1
			WHILE @iCompteur <= LEN(@vcCaracteres_Remplacement)/2
				BEGIN
					IF CHARINDEX(SUBSTRING(@vcCaracteres_Remplacement,(@iCompteur*2)-1,1),@vcNom) > 0
						BEGIN
							SET @vcCaracteres_Modifies = @vcCaracteres_Modifies + SUBSTRING(@vcCaracteres_Remplacement,(@iCompteur*2)-1,1)
							SET @vcNom = REPLACE(@vcNom,SUBSTRING(@vcCaracteres_Remplacement,(@iCompteur*2)-1,1),
														SUBSTRING(@vcCaracteres_Remplacement,@iCompteur*2,1))
						END
					SET @iCompteur = @iCompteur + 1
				END

			-- Supprimer les caractères
			SET @iCompteur = 1
			WHILE @iCompteur <= LEN(@vcCaracteres_Suppression)
				BEGIN
					IF CHARINDEX(SUBSTRING(@vcCaracteres_Suppression,@iCompteur,1),@vcNom) > 0
						BEGIN
							SET @vcCaracteres_Modifies = @vcCaracteres_Modifies + SUBSTRING(@vcCaracteres_Suppression,@iCompteur,1)
							SET @vcNom = REPLACE(@vcNom,SUBSTRING(@vcCaracteres_Suppression,@iCompteur,1),'')
						END
					SET @iCompteur = @iCompteur + 1
				END
		END

	-- Retourner les valeurs
	IF @vcCaracteres_Modifies = ''
		SET @vcCaracteres_Modifies = NULL

	INSERT @tblIQEE_Nom (vcNom,vcCaracteres_Modifies)
	VALUES (@vcNom,@vcCaracteres_Modifies)

	RETURN
END

