/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_ConventionForRESOfSubscriber
Description         :	Retourne la liste des conventions qui ne sont pas résiliées ni en remboursement intégral pour
								un souscripteur.
Valeurs de retours  :	Dataset :
									ConventionID	INTEGER		ID de la convention.
									ConventionNo	VARCHAR(75)	Numéro de convention.
Note                :	ADX0000799	IA	2006-01-31	Bruno Lapointe		Création
                                        2018-02-13  Pierre-Luc Simard   Exclure aussi les RIN partiel
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_ConventionForRESOfSubscriber] (
	@SubscriberID INTEGER ) -- ID du souscripteur.
AS
BEGIN
	SELECT DISTINCT
		C.ConventionID, -- ID de la convention.
		C.ConventionNo -- Numéro de convention.
	FROM dbo.Un_Convention C
	JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
    LEFT JOIN dbo.fntCONV_ObtenirStatutRINUnite(NULL, NULL, GETDATE()) RIN ON RIN.UnitID = U.UnitID
	WHERE C.SubscriberID = @SubscriberID
		AND U.TerminatedDate IS NULL
		--AND U.IntReimbDate IS NULL
        AND ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les groupes d'unités avec un RIN partiel ou complet
	ORDER BY C.ConventionNo
END