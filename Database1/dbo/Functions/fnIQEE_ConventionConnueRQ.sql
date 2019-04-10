/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnIQEE_ConventionConnueRQ
Nom du service		: Convention connue de RQ
But 				: Déterminer si une convention est connue de RQ à une date de référence.
Facette				: IQÉÉ

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

Exemple d’appel		:	SELECT [dbo].[fnIQEE_ConventionConnueRQ](300000,NULL,NULL,NULL)

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							bConventionConnueRQ				0 = La convention n'est pas connue
																						de RQ à la date de référence
																					1 = La convention est connue
																						de RQ à la date de référence

Historique des modifications:
	Date        Programmeur                 Description
	----------  ------------------------    ---------------------------------------------------------------------------
    2009-04-22  Éric Deshaies               Création du service							
    2012-06-19  Stéphane Barbeau            Ajustement de la logique pour la reconnaissance de la convention
    2013-11-22  Stéphane Barbeau            Rendre obligatoire le paramètre @dtDate_Reference
                                            Vérification de @dtDate_Reference dans les T02, T03, T04 et T05 pour déduire que la convention est connue.
    2015-03-20  Stéphane Barbeau            Allègement des requêtes des IF EXISTS (changer * pour top 1).
    2016-02-18  Steeve Picard               Utilisation de la nouvelle fonction globale
    2017-11-09  Steeve Picard               Ajout du paramètre «siAnnee_Fiscale» à la fonction «fntIQEE_ConventionConnueRQ_PourTous»
    2017-12-05  Steeve Picard               Éliminer le paramètre «dtReference» pour filtrer seulement sur l'année fiscale et retourne la date reconnue
***********************************************************************************************************************/
CREATE FUNCTION dbo.fnIQEE_ConventionConnueRQ
(
	@iID_Convention INT,
    @siAnnee_Fiscale SMALLINT = NULL
)
RETURNS DATE 
AS
BEGIN
    DECLARE @dtReconnue AS DATE
    
	SELECT @dtReconnue = X.dtReconnue_RQ 
      FROM fntIQEE_ConventionConnueRQ_PourTous(@iID_Convention, @siAnnee_Fiscale) X

    RETURN @dtReconnue
END 
