/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */

/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnGENE_AdresseEnDate
Nom du service		: Déterminer l’adresse à une date
But 				: Retourner l’adresse d’une personne ou d’une entreprise à une date donnée.
Facette				: GENE
Référence			: UniAccès-Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				iID_Humain					Identifiant de l’humain (personne ou entreprise).
						dtDate						Date pour laquelle l’adresse doit être déterminée.   Si la date
													n’est pas fournie, on considère que c’est pour la date du jour.

Exemple d’appel		:	exec [dbo].[fnGENE_AdresseEnDate] 243466, '2008-01-01'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						Mo_Adr						AdrID							Identifiant de l’adresse à la date
																					demandée.  S’il n’y a pas d’adresse
																					à la date demandée, l’identifiant
																					de l’adresse en cours de l’humain
																					est retourné.

Historique des modifications:
    Date        Programmeur                 Description
    ----------  ------------------------    --------------------------------------------------------
    2008-05-29  Éric Deshaies               Création du service							
                Steeve Picard               Cette fonction a été renommé
****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_AdresseEnDate]
(
	@iID_Humain int,
	@dtDate datetime
)
RETURNS int
AS
BEGIN
	-- Si l'identifiant de l'humain est vide, retourner 0
	IF @iID_Humain IS NULL or @iID_Humain = 0
		RETURN 0

	DECLARE
		@iID_Adresse int,
		@dtDate_TMP datetime
     	
	-- Utiliser la date du jour si la date n'est pas spécifié en paramètre
	IF @dtDate IS NULL
		SET @dtDate_TMP = GETDATE()
	ELSE
		SET @dtDate_TMP = @dtDate
	
	-- Rechercher l'adresse de l'humain à la date demandée
     SELECT @iID_Adresse = A.iID_Adresse
       FROM dbo.fntGENE_ObtenirAdresseEnDate(@iID_Humain, DEFAULT, @dtDate_TMP, DEFAULT) A

	-- Retourner l'identifiant de l'adresse trouvée
	IF @iID_Adresse IS NOT NULL AND @iID_Adresse <> 0
		RETURN @iID_Adresse

	-- Rechercher l'adresse en cours de l'humain s'il n'y a pas d'adresse à la date demandée
     SELECT @iID_Adresse = A.iID_Adresse
       FROM dbo.fntGENE_ObtenirAdresseEnDate(@iID_Humain, DEFAULT, DEFAULT, DEFAULT) A

	-- Retourner l'identifiant de l'adresse en cours
	IF @iID_Adresse IS NOT NULL AND @iID_Adresse <> 0
		RETURN @iID_Adresse

	-- Retourner 0 lorsqu'il n'y en a aucune adresse pour l'humain
	RETURN 0
END