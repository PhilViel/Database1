/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnIQEE_ValiderNom
Nom du service		: Valider un nom de l’IQÉÉ
But 				: Valider un prénom ou nom de l’IQÉÉ au niveau du jeu de caractères.  Annexe 1 des NID.
Facette				: IQEE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				vcNom						Nom ou prénom.

Exemple d’appel		:	SELECT [dbo].[fnIQEE_ValiderNom]('`"sdfg%$sdfgsdfg?SFSDF*()erer')

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							vcCaracteres_Non_Admissible		Caractères non admissibles et/ou
																					indication que le premier caractère
																					n’est pas une lettre.

Historique des modifications :
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-02-05		Éric Deshaies						Création du service							
        2018-13-17      Steeve Picard                       Ajout des caractères « Á á » comme acceptable
****************************************************************************************************/
CREATE FUNCTION dbo.fnIQEE_ValiderNom
(
	@vcNom VARCHAR(20)
)
RETURNS VARCHAR(40)
AS
BEGIN
	-- NULL est nécessairement valide
	IF @vcNom IS NULL
		RETURN NULL

	DECLARE
		@vcResultat VARCHAR(40),
		@vcCaracteres_Admissibles VARCHAR(200),
		@iCompteur INT

	-- Trouver les caractères non admissible partout dans la chaîne
	SET @vcCaracteres_Admissibles = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz /-&''’'+
									   'ÇçÀàÂâÄäÁáÉéÈèÊêËëÌìÎîÏïíÒòÔôÖöóÙùÛûÜüúYyŸÿÑñ.'
	SET @iCompteur = 1
	SET @vcResultat = ''
	WHILE @iCompteur <= LEN(@vcNom)
		BEGIN
			IF CHARINDEX(SUBSTRING(@vcNom,@iCompteur,1),@vcCaracteres_Admissibles) = 0
				SET @vcResultat = @vcResultat + SUBSTRING(@vcNom,@iCompteur,1)
			SET @iCompteur = @iCompteur + 1
		END

	-- Trouver les caractères non admissible au premier caractère
	SET @vcCaracteres_Admissibles = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'+
									   'ÇçÀàÂâÄäÉéÈèÊêËëÌìÎîÏïíÒòÔôÖöóÙùÛûÜüúYyŸÿÑñ'
	IF CHARINDEX(SUBSTRING(@vcNom,1,1),@vcCaracteres_Admissibles) = 0
		BEGIN
			IF @vcResultat = ''
				SET @vcResultat = '1er caractère' + @vcResultat
			ELSE
				SET @vcResultat = '1er caractère, ' + @vcResultat
		END

	-- Retourner les caractères en erreurs
	IF @vcResultat = ''
		SET @vcResultat = NULL

	RETURN @vcResultat
END
