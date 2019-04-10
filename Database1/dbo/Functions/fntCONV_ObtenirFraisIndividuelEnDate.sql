/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service     : fntCONV_ObtenirFraisIndividuelEnDate
Nom du service		: fntCONV_ObtenirFraisIndividuelEnDate
But 				: Permet d'obtenir les frais cotisé de toutes les conventions individuel en fonction d'une date
Description		    : Cette fonction est appelée à chaque fois qu'il est nécesaire d'obtenir les frais cotisé d'une convention individuel
Facette			    : CONV
Référence			: 

Paramètres d’entrée	:	Paramètre				Obligatoire	Description
					--------------------------	-----------	-----------------------------------------------------------------
					@dtDate						Non			Date à laquelle on veut récupérer les frais, par défaut, date du jour
					@idConvention				Non			ID de la convention pour laquelle on veut les frais, par défaut, pour tous

Exemple d'appel : 
        SELECT * FROM dbo.fntCONV_ObtenirFraisIndividuelEnDate(NULL, NULL)
        SELECT * FROM dbo.fntCONV_ObtenirFraisIndividuelEnDate(NULL, 466933)
        SELECT * FROM dbo.fntCONV_ObtenirFraisIndividuelEnDate('2017-05-15', NULL)
        SELECT * FROM dbo.fntCONV_ObtenirFraisIndividuelEnDate('2017-05-14', 370289)

NE PAS OUBLIER DE CHANGER LA FONCTION DANS LE C# (GUI.Domain.PortailClient.Entities.Convention -> ObtenirFraisConventionIndividuelle)

Historique des modifications:
        Date        Programmeur			Description						Référence
        ----------  ------------------  ---------------------------  	------------
        2015-09-30  Maxime Martel       Création de la fonction			JIRA : MC-431 Créer la fonction calcul de frais

*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirFraisIndividuelEnDate]
(
	@dtDateFin DATETIME = NULL,
	@idConvention INT = NULL
)
RETURNS TABLE AS
RETURN (
	WITH CTE_Unit AS (
		SELECT 
			C.ConventionID,
			C.ConventionNo,
			U.UnitID,
			U.UnitQty
		FROM Un_Convention C
		JOIN Un_Unit U ON U.ConventionID = C.ConventionID
        WHERE C.ConventionID = ISNULL(@idConvention, C.ConventionID)
            AND C.PlanID = 4 -- Individuel
			AND C.ConventionNo not like 'T%'
    ), CTE_Cotisation AS (
        SELECT 
            U.ConventionID,
		    U.ConventionNo,
            U.UnitID,
            mSolde_Frais_Sans_RIN = SUM(CT.Fee)                                     
        FROM CTE_Unit U 
        JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = CT.OperID
		LEFT JOIN Un_OtherAccountOper OAO ON OAO.OperID = O.OperID
		LEFT JOIN Un_IntReimbOper IRO ON IRO.OperID = OAO.OperID
		LEFT JOIN tblOPER_OperationsRIO R ON R.iID_Oper_RIO = O.OperID AND R.iID_Unite_Source = U.UnitID AND R.bRIO_Annulee = 0 AND R.bRIO_QuiAnnule = 0
        WHERE O.OperDate <= ISNULL(@dtDateFin, GETDATE())
            AND O.OperTypeID <> 'RIN' -- Exclure les RIN
			AND R.iID_Operation_RIO IS NULL -- Exclure les RIM, RIO et TRI sortant
			AND IRO.OperID IS NULL -- Exclure les frais éliminés suite à un RIN
        GROUP BY 
            U.ConventionID,
		    U.ConventionNo,
            U.UnitID
	)
	SELECT 
		U.ConventionID,
		U.ConventionNo,
		U.UnitID,
		Frais = ISNULL(F.mSolde_Frais_Sans_RIN, 0)
	FROM CTE_Unit U
	LEFT JOIN CTE_Cotisation F ON F.UnitID = U.UnitID
    )