/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_RepUnitQtyForPeriod 
Description         :	Retourne toutes les groupes d’unités avec le nombre d’unités qu’ils avaient à la date passée
								en paramètre.  Le champ UnitQty du groupe d'unités est mis à jour immédiatement lors d'une
								réduction d'unités même si cette dernière est datée ultérieurement.  Pour connaître le nombre
								réel d'unités qu'il y avait dans un groupe d'unités à une date précise, il faut donc
								additionné au champ Un_Unit.UnitQty le nombre d'unités résilié ultérieurement à la date.
Valeurs de retours  :	Dataset :
									UnitID	INTEGER	ID unique du groupe d’unité.	
									UnitQty	MONEY		Nombre d’unités à la date saisie.
Note                :	ADX0000696	IA	2005-08-16	Bruno Lapointe		Création
						JIRA: MC-385	2018-04-12	Maxime Martel		Utilisé le nombre d'unité selon les frais pour l'individuel
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_RepUnitQtyForPeriod] (
	@RepTreatmentDate DATETIME ) -- Dernier jour inclusivement à traiter.
AS
BEGIN
	SELECT 
		U.UnitID, -- ID du groupe d'unités
        UnitQty = U.UnitQty + ISNULL(VR.UnitReductQty, 0) -- Nombre d'unités en date du traitement (Inclus les unités résiliés ultérieurement)
		--UnitQty = CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE U.UnitQty + ISNULL(VR.UnitReductQty, 0) END, -- Nombre d'unités en date du traitement (Inclus les unités résiliés ultérieurement)
        --UnitQtyReel = U.UnitQty + ISNULL(VR.UnitReductQty, 0) -- Nombre d'unités en date du traitement (Inclus les unités résiliés ultérieurement)
	FROM dbo.Un_Unit U
	JOIN Un_Convention C on C.ConventionID = U.ConventionID
	LEFT JOIN (
		SELECT 
			UnitID, -- ID du groupe d'unités
			UnitReductQty  =  SUM(UnitQty) -- Nombre d'unités résiliés ultérieurement
		FROM Un_UnitReduction
		WHERE ReductionDate > @RepTreatmentDate
		GROUP BY UnitID
		) VR ON VR.UnitID = U.UnitID
	--LEFT JOIN dbo.fntCONV_ObtenirNombreUniteIndividuelSelonFraisEnDate(@RepTreatmentDate, NULL) UI on UI.UnitID = U.UnitID
END