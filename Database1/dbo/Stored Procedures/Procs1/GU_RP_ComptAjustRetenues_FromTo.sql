/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	GU_RP_ComptAjustRetenues
Description         :	Rapport historique des ajustements et retenues des représentants pour la création du fichier Excel
Valeurs de retours  :	Dataset 
Note                :	Pierre-Luc Simard	2008-01-17 	
						Donald Huppé		2011-01-13	correction du calcul du statu Actif.  faire < ou lieu de <=
						Donald Huppé		2011-01-14	Autre correction du calcul du statu Actif.  faire < ou lieu de <=
						Donald Huppé		2011-03-18	Ajout du paramètre TRI (glpi 5229)
						Donald Huppé		2018-09-04	jira prod-11663 : Ajout de RepCodeINT
						
exec GU_RP_ComptAjustRetenues_FromTo 421,425, 'TOus', 'Nom'

select * from un_reptreatment

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_ComptAjustRetenues_FromTo]
(
	@ReptreatmentIDFrom INTEGER,
	@ReptreatmentIDTo INTEGER,
	@Statut Varchar(15), -- Actif Inactif Tous
	@Tri varchar(5)-- 'Code' = Code du Rep, 'Nom' = Nom de famille du rep
) 

AS
BEGIN
	SET NOCOUNT ON

	DECLARE @RepTreatmentDateFrom MoDate
	DECLARE @RepTreatmentDateTo MoDate

	-- Lecture de la date du premier traitement choisi
	SELECT @RepTreatmentDateFrom = RepTreatmentDate
	FROM Un_Reptreatment
	WHERE RepTreatmentID = @RepTreatmentIDFrom

	-- Lecture de la date du dernier traitement choisi
	SELECT @RepTreatmentDateTo = RepTreatmentDate
	FROM Un_Reptreatment
	WHERE RepTreatmentID = @RepTreatmentIDTo

	SELECT 
		Statut = --Indique si un représentant est actif (1) ou inactif (0) pour tier les données
			CASE
				WHEN isnull(Un_Rep.BusinessEnd,'3000-01-01') < RT.RepTreatmentDate THEN 0
			ELSE 1
			END,
		StatutDesc = -- Description du statut
			CASE
				WHEN isnull(Un_Rep.BusinessEnd,'3000-01-01') < RT.RepTreatmentDate THEN 'Inactifs'
			ELSE 'Actifs'
			END,
		Un_Rep.RepCode, -- Code du représentant
		LastName = Mo_Human.LastName + case 
					when isnull(Un_Rep.BusinessEnd,'3000-01-01') >= RT.RepTreatmentDate and @Statut = 'Tous' then ' (a)' 
					when isnull(Un_Rep.BusinessEnd,'3000-01-01') < RT.RepTreatmentDate and @Statut = 'Tous' then ' (i)' 
					else '' end, -- Nom du représentant
		Mo_Human.FirstName, -- Prénom du représentant
		Un_Rep.BusinessEnd, -- Date de fin du représentant
		Un_RepCharge.RepChargeDate, -- Date de la transaction
		Un_RepChargeType.RepChargeTypeDesc, -- Type de la transaction 
		Un_RepCharge.RepChargeDesc, -- Description de la transaction
		Un_RepCharge.RepChargeAmount, -- Montant de la transaction
		RepTreatFrom = @RepTreatmentIDFrom,
		RepTreatTo = @RepTreatmentIDTo,
		RepTDateFrom = @RepTreatmentDateFrom,
		RepTDateTo = @RepTreatmentDateTo,
		RepCodeINT = CASE WHEN ISNUMERIC(Un_Rep.RepCode) = 1 THEN CAST(Un_Rep.RepCode AS INT) ELSE 0 END
	FROM 
		Un_RepCharge 
		JOIN Un_repTreatment RT on Un_RepCharge.ReptreatmentID = RT.ReptreatmentID
		JOIN Un_RepChargeType ON Un_RepCharge.RepChargeTypeID = Un_RepChargeType.RepChargeTypeID 
		JOIN Un_Rep ON Un_RepCharge.RepID = Un_Rep.RepID 
		JOIN dbo.Mo_Human ON Un_Rep.RepID = Mo_Human.HumanID
	WHERE 
		Un_RepCharge.RepTreatmentID between @ReptreatmentIDFrom and @ReptreatmentIDTo
		and (
			@Statut = 'Actif' and isnull(Un_Rep.BusinessEnd,'3000-01-01') >= RT.RepTreatmentDate
			OR
			@Statut = 'Inactif' and isnull(Un_Rep.BusinessEnd,'3000-01-01') < RT.RepTreatmentDate
			OR
			@Statut = 'Tous'
			)
	order by 
		case 
			when @Tri = 'Code' then Un_Rep.RepCode
			when @Tri = 'Nom' then Mo_Human.LastName
			else repcode
		end,
		Un_RepChargeType.RepChargeTypeDesc, 
		Un_RepCharge.RepChargeDate
END

