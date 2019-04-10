/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnGENE_ObtenirParametre
Nom du service		: Obtenir un paramètre
But 				: Obtenir la valeur en vigueur d’un paramètre selon les dimensions fournies.
Facette				: GENE
Référence			: Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				vcCode_Type_Parametre		Identifiant unique du type de paramètre à mettre à jour.
						dtDate_Application			Date du paramètre.
						vcDimension1				Valeur de la dimension1 du paramètre.
						vcDimension2				Valeur de la dimension2 du paramètre.
						vcDimension3				Valeur de la dimension3 du paramètre.
						vcDimension4				Valeur de la dimension4 du paramètre.
						vcDimension5				Valeur de la dimension5 du paramètre.

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							vcCode_Retour					vcValeur_Parametre = Traitement réussi
																					-1 = Type de paramètre inexistant
																					-2 = Valeur de Parametre inexistant
Historique des modifications:
		Date			Programmeur					Description						Référence
		------------	-------------------------	---------------------------  	------------
		2008-09-12		Josée Parent				Création du service							
		2008-12-12		Patrice Péau				Permettre le NULL sur la date
		2009-05-29		Jean-François Gauthier		Passage à VARCHAR(MAX) pour la valeur de retour
													et pour la variable @vcCode_Retour
****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_ObtenirParametre]
(
	@vcCode_Type_Parametre		VARCHAR(100),
	@dtDate_Application			DATETIME = NULL,
	@vcDimension1				VARCHAR(100),
	@vcDimension2				VARCHAR(100),
	@vcDimension3				VARCHAR(100),
	@vcDimension4				VARCHAR(100),
	@vcDimension5				VARCHAR(100)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
	DECLARE @vcCode_Retour			VARCHAR(MAX);
	DECLARE @iIDCode_Type_Parametre	INT;
	DECLARE @tiNB_Dimensions		TINYINT;
	DECLARE @iCount_Valeur			INT,
			@bConserver_Historique	BIT;

	-- Sélectionne l'ID du type de parametre spédifié.
	SELECT @iIDCode_Type_Parametre = iID_Type_Parametre,
		   @bConserver_Historique = bConserver_Historique,
		   @tiNB_Dimensions = tiNB_Dimensions
	FROM tblGENE_TypesParametre
	WHERE vcCode_Type_Parametre = @vcCode_Type_parametre

	IF @iIDCode_Type_Parametre IS NULL
	BEGIN
		-- Le type de parametre spécifié n'exite pas !  On retourne -1
		SET @vcCode_Retour = '-1';
	END
	ELSE
	BEGIN
		SET @iCount_Valeur = NULL;

		IF @dtDate_Application IS NULL
			SET @dtDate_Application = GETDATE();

		-- Selectionne le parametre s'il n'y a pas de dimension
		IF @tiNB_Dimensions = 0 OR
		  (@vcDimension1 IS NULL AND @vcDimension2 IS NULL AND @vcDimension3 IS NULL AND @vcDimension4 IS NULL AND @vcDimension5 IS NULL)
		BEGIN
			SELECT TOP 1 @vcCode_Retour = vcValeur_Parametre, @iCount_Valeur = COUNT(vcValeur_Parametre) FROM tblGENE_Parametres
			WHERE iID_Type_Parametre = @iIDCode_Type_Parametre
			AND (@dtDate_Application BETWEEN dtDate_Debut_Application AND ISNULL(dtDate_Fin_Application,DATEADD(YEAR,1000,GETDATE()))
				 OR (@bConserver_Historique = 0 AND dtDate_Fin_Application IS NULL))
			AND vcDimension1 IS NULL
			AND vcDimension2 IS NULL
			AND vcDimension3 IS NULL
			AND vcDimension4 IS NULL
			AND vcDimension5 IS NULL
			GROUP BY vcValeur_Parametre
		END
		ELSE
		BEGIN
			-- Selectionne le parametre avec les 5 dimensions de spécifié, s'il ne trouve
			-- pas de paramètre, on essaie avec 4 dimensions, et ainsi de suite.
			IF @vcDimension1 IS NOT NULL AND @vcDimension2 IS NOT NULL AND @vcDimension3 IS NOT NULL AND @vcDimension4 IS NOT NULL AND @vcDimension5 IS NOT NULL
			BEGIN
				SELECT TOP 1 @vcCode_Retour = vcValeur_Parametre, @iCount_Valeur = COUNT(vcValeur_Parametre) FROM tblGENE_Parametres
				WHERE iID_Type_Parametre = @iIDCode_Type_Parametre
				AND (@dtDate_Application BETWEEN dtDate_Debut_Application AND ISNULL(dtDate_Fin_Application,DATEADD(YEAR,1000,GETDATE()))
					 OR (@bConserver_Historique = 0 AND dtDate_Fin_Application IS NULL))
				AND ISNULL(vcDimension1,'PAS DE DIMENSION') = @vcDimension1
				AND ISNULL(vcDimension2,'PAS DE DIMENSION') = @vcDimension2
				AND ISNULL(vcDimension3,'PAS DE DIMENSION') = @vcDimension3
				AND ISNULL(vcDimension4,'PAS DE DIMENSION') = @vcDimension4
				AND ISNULL(vcDimension5,'PAS DE DIMENSION') = @vcDimension5
				GROUP BY vcValeur_Parametre
			END

			-- Selectionne le parametre avec les 4 dimensions de spécifié, s'il ne trouve
			-- pas de paramètre, on essaie avec 3 dimensions, et ainsi de suite.
			IF @iCount_Valeur IS NULL AND @vcDimension1 IS NOT NULL AND @vcDimension2 IS NOT NULL AND @vcDimension3 IS NOT NULL AND @vcDimension4 IS NOT NULL
			BEGIN
				SELECT TOP 1 @vcCode_Retour = vcValeur_Parametre, @iCount_Valeur = COUNT(vcValeur_Parametre) FROM tblGENE_Parametres
				WHERE iID_Type_Parametre = @iIDCode_Type_Parametre
				AND (@dtDate_Application BETWEEN dtDate_Debut_Application AND ISNULL(dtDate_Fin_Application,DATEADD(YEAR,1000,GETDATE()))
					 OR (@bConserver_Historique = 0 AND dtDate_Fin_Application IS NULL))
				AND ISNULL(vcDimension1,'PAS DE DIMENSION') = @vcDimension1
				AND ISNULL(vcDimension2,'PAS DE DIMENSION') = @vcDimension2
				AND ISNULL(vcDimension3,'PAS DE DIMENSION') = @vcDimension3
				AND ISNULL(vcDimension4,'PAS DE DIMENSION') = @vcDimension4
				AND vcDimension5 IS NULL
				GROUP BY vcValeur_Parametre
			END

			-- Selectionne le parametre avec les 3 dimensions de spécifié, s'il ne trouve
			-- pas de paramètre, on essaie avec 2 dimensions, et ainsi de suite.
			IF @iCount_Valeur IS NULL AND @vcDimension1 IS NOT NULL AND @vcDimension2 IS NOT NULL AND @vcDimension3 IS NOT NULL
			BEGIN
				SELECT TOP 1 @vcCode_Retour = vcValeur_Parametre, @iCount_Valeur = COUNT(vcValeur_Parametre) FROM tblGENE_Parametres
				WHERE iID_Type_Parametre = @iIDCode_Type_Parametre
				AND (@dtDate_Application BETWEEN dtDate_Debut_Application AND ISNULL(dtDate_Fin_Application,DATEADD(YEAR,1000,GETDATE()))
					 OR (@bConserver_Historique = 0 AND dtDate_Fin_Application IS NULL))
				AND ISNULL(vcDimension1,'PAS DE DIMENSION') = @vcDimension1
				AND ISNULL(vcDimension2,'PAS DE DIMENSION') = @vcDimension2
				AND ISNULL(vcDimension3,'PAS DE DIMENSION') = @vcDimension3
				AND vcDimension4 IS NULL
				AND vcDimension5 IS NULL
				GROUP BY vcValeur_Parametre
			END

			-- Selectionne le parametre avec les 2 dimensions de spécifié, s'il ne trouve
			-- pas de paramètre, on essaie avec 1 dimensions, et ainsi de suite.
			IF @iCount_Valeur IS NULL AND @vcDimension1 IS NOT NULL AND @vcDimension2 IS NOT NULL
			BEGIN
				SELECT TOP 1 @vcCode_Retour = vcValeur_Parametre, @iCount_Valeur = COUNT(vcValeur_Parametre) FROM tblGENE_Parametres
				WHERE iID_Type_Parametre = @iIDCode_Type_Parametre
				AND (@dtDate_Application BETWEEN dtDate_Debut_Application AND ISNULL(dtDate_Fin_Application,DATEADD(YEAR,1000,GETDATE()))
					 OR (@bConserver_Historique = 0 AND dtDate_Fin_Application IS NULL))
				AND ISNULL(vcDimension1,'PAS DE DIMENSION') = @vcDimension1
				AND ISNULL(vcDimension2,'PAS DE DIMENSION') = @vcDimension2
				AND vcDimension3 IS NULL
				AND vcDimension4 IS NULL
				AND vcDimension5 IS NULL
				GROUP BY vcValeur_Parametre
			END

			-- Selectionne le parametre avec les 1 dimensions de spécifié, s'il ne trouve
			-- pas de paramètre, on essaie avec aucune dimension, et ainsi de suite.
			IF @iCount_Valeur IS NULL AND @vcDimension1 IS NOT NULL
			BEGIN
				SELECT TOP 1 @vcCode_Retour = vcValeur_Parametre, @iCount_Valeur = COUNT(vcValeur_Parametre) FROM tblGENE_Parametres
				WHERE iID_Type_Parametre = @iIDCode_Type_Parametre
				AND (@dtDate_Application BETWEEN dtDate_Debut_Application AND ISNULL(dtDate_Fin_Application,DATEADD(YEAR,1000,GETDATE()))
					 OR (@bConserver_Historique = 0 AND dtDate_Fin_Application IS NULL))
				AND ISNULL(vcDimension1,'PAS DE DIMENSION') = @vcDimension1
				AND vcDimension2 IS NULL
				AND vcDimension3 IS NULL
				AND vcDimension4 IS NULL
				AND vcDimension5 IS NULL
				GROUP BY vcValeur_Parametre
			END

			-- Selectionne le parametre avec aucune dimension de spécifié, s'il ne trouve
			-- pas de paramètre, on retourne -2 pour spécifer que le parametre n'existe pas.
			IF @iCount_Valeur IS NULL
			BEGIN
				SELECT TOP 1 @vcCode_Retour = vcValeur_Parametre, @iCount_Valeur = COUNT(vcValeur_Parametre) FROM tblGENE_Parametres
				WHERE iID_Type_Parametre = @iIDCode_Type_Parametre
				AND (@dtDate_Application BETWEEN dtDate_Debut_Application AND ISNULL(dtDate_Fin_Application,DATEADD(YEAR,1000,GETDATE()))
					 OR (@bConserver_Historique = 0 AND dtDate_Fin_Application IS NULL))
				AND vcDimension1 IS NULL
				AND vcDimension2 IS NULL
				AND vcDimension3 IS NULL
				AND vcDimension4 IS NULL
				AND vcDimension5 IS NULL
				GROUP BY vcValeur_Parametre
			END
		END
	
		--Le parametre n'existe pas, on retourne -2
		IF @iCount_Valeur IS NULL
			SET @vcCode_Retour = '-2';
	END

	-- Return the result of the function
	RETURN @vcCode_Retour
END
