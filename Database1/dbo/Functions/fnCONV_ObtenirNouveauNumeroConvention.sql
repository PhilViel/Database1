/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnCONV_ObtenirNouveauNumeroConvention
Nom du service		: Obtenir un nouveau numéro de convention
But 						: Obtenir un nouveau numéro de convention.
Facette					: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Convention				Identifiant de la convention que l'on désire savoir si elle est
													connue ou non de RQ.
						dtDate_Reference			Date à laquelle on désire savoir si la convention est connue de RQ.
													Si elle est absente, la date du jour est considérée.
						iID_Fichier_IQEE			Identifiant du nouveau fichier de transactions en cours de
													création s'il y a lieu.												
						bFichiers_Test_Comme_		Indicateur si les fichiers test doivent être tenue en compte dans
							Production				les transactions sélectionnées pour déterminer si la convention est
													connue ou non de RQ.  Normalement ce n’est pas le cas.  Mais
													pour fins d’essais et de simulations il est possible de tenir compte
													des fichiers tests comme des fichiers de production.  S’il est absent,
													les fichiers test ne sont pas considérés.

Exemple d’appel		:	SELECT [dbo].[fnCONV_ObtenirNouveauNumeroConvention](12, '2014-09-12', 'Z')
								SELECT [dbo].[fnCONV_ObtenirNouveauNumeroConvention](12, NULL, NULL)

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							bConventionConnueRQ				0 = La convention n'est pas connue
																						de RQ à la date de référence
																					1 = La convention est connue
																						de RQ à la date de référence

Historique des modifications:
		Date		Programmeur				Description								
		----------	----------------------  -----------------------------------------	
		2014-09-15	Pierre-Luc Simard		Création du service à partir de IU_UN_Convention	
        2018-10-29  Pierre-Luc Simard       Utilisation du champ cLettre_PrefixeConventionNo						
****************************************************************************************************/
CREATE FUNCTION [dbo].[fnCONV_ObtenirNouveauNumeroConvention]
(
	@iID_Plan INT
	,@dtDate_Convention DATETIME 
	,@vcNumero_Convention VARCHAR(15) = ''
)
RETURNS VARCHAR(15)
AS
BEGIN

	DECLARE
		@bCarac BIT	
		,@iPosition INT
		,@cLettre CHAR(1)
		,@iConventionNo3Last	 INT
		,@vcNumero_ConventionTemp VARCHAR(15)
					
	-- Assigne la date reçu en paramètre, sinon la date du jour
	SET @dtDate_Convention = ISNULL(@dtDate_Convention,GETDATE())

	-- Initialiser les variables
	SET @iPosition = 1
	SET @bCarac = 0
	-- Boucle pour tester l'existence de caracteres au niveau du @vcNumero_Convention
	WHILE (@iPosition <= LEN(@vcNumero_Convention) AND @bCarac=0) 
	BEGIN
		IF(ASCII(SUBSTRING(@vcNumero_Convention,@iPosition,1)) NOT BETWEEN 48 AND 57)
			BEGIN
				SET @cLettre = SUBSTRING(@vcNumero_Convention,@iPosition,1)
				SET @vcNumero_Convention = @cLettre +'-'+ CONVERT(VARCHAR (8),(@dtDate_Convention),112) -- Nassim: permet de formater le numero de Convention selon 1er Caractere trouve + Date Pmt en format de 8 chiffre (yyyymmdd)
				SET @bCarac = 1
			END
		SET @iPosition = @iPosition +1
	END

	--si on n'a pas trouvé de caractères, on le crée comme avant
	IF (@bCarac = 0)
	BEGIN
			
		SET @dtDate_Convention = GETDATE()

        SELECT 
            @vcNumero_Convention = ISNULL(P.cLettre_PrefixeConventionNo, '') + '-' + CAST(YEAR(@dtDate_Convention) AS CHAR(4)) 
        FROM Un_Plan P
        WHERE P.PlanID = @iID_Plan
        /*
		IF @iID_Plan = 4
			SET @vcNumero_Convention = 'I-' + CAST(YEAR(@dtDate_Convention) AS CHAR(4))
		ELSE IF @iID_Plan = 8
			SET @vcNumero_Convention = 'U-' + CAST(YEAR(@dtDate_Convention) AS CHAR(4))
		ELSE IF @iID_Plan = 10
			SET @vcNumero_Convention = 'R-' + CAST(YEAR(@dtDate_Convention) AS CHAR(4))
		ELSE IF @iID_Plan = 11
			SET @vcNumero_Convention = 'B-' + CAST(YEAR(@dtDate_Convention) AS CHAR(4))
		ELSE IF @iID_Plan = 12
			SET @vcNumero_Convention = 'X-' + CAST(YEAR(@dtDate_Convention) AS CHAR(4))
        */
		IF MONTH(@dtDate_Convention) > = 10
			SET @vcNumero_Convention = @vcNumero_Convention + CAST(MONTH(@dtDate_Convention) AS  CHAR(2))
		ELSE
			SET @vcNumero_Convention = @vcNumero_Convention + '0' + CAST(MONTH(@dtDate_Convention) AS  CHAR(1))

		IF DAY(@dtDate_Convention) > = 10
			SET @vcNumero_Convention = @vcNumero_Convention + CAST(DAY(@dtDate_Convention) AS  CHAR(2))
		ELSE
			SET @vcNumero_Convention = @vcNumero_Convention + '0' + CAST(DAY(@dtDate_Convention) AS  CHAR(1))

	END
		
	SELECT @iConventionNo3Last = COUNT(1) + 1
	FROM dbo.Un_Convention 
	WHERE ConventionNo LIKE (@vcNumero_Convention + '%')
		
	IF @iConventionNo3Last > 999
		SET @vcNumero_ConventionTemp = @vcNumero_Convention + RIGHT('0000'+ CONVERT(VARCHAR, @iConventionNo3Last), 4)
	ELSE
		SET @vcNumero_ConventionTemp = @vcNumero_Convention + RIGHT('000'+ CONVERT(VARCHAR, @iConventionNo3Last), 3)
		
	WHILE EXISTS (SELECT 1 FROM dbo.Un_Convention WHERE ConventionNo = @vcNumero_ConventionTemp)
	BEGIN
		SET @iConventionNo3Last = @iConventionNo3Last + 1

		IF @iConventionNo3Last > 999
			SET @vcNumero_ConventionTemp = @vcNumero_Convention + RIGHT('0000'+ CONVERT(VARCHAR, @iConventionNo3Last), 4)
		ELSE
			SET @vcNumero_ConventionTemp = @vcNumero_Convention + RIGHT('000'+ CONVERT(VARCHAR, @iConventionNo3Last), 3)
	END
		
	SET @vcNumero_Convention = @vcNumero_ConventionTemp

	RETURN @vcNumero_Convention

END