CREATE PROC [dbo].[SP_CrqSearchRepTreatment] (
										@EffectDays MoID = 0, -- nombre de jours d'attente requis jusqu'à la date actuelle
										@TreatmentCount MoID = 0 -- nombre de traitements retournés
									) 
AS
-----------------------------------------------------------------
-- STORED PROCEDURE DE RECHERCHE DES TRAITEMENTS DES COMMISSIONS
-----------------------------------------------------------------
/* 2009-06-05	Pierre-Luc Simard	Le traitement des commissions se fait maintenant le dimanche comme avant, mais en date du dimanche et non du samedi
									On enlève donc une journée au nombre de jour d'attente envoyé en paramètre par l'application pour rendre disponibles les 
									rapports le mercredi au représentant, comme avant, et non le jeudi.  	

	2009-10-21	Donald Huppé			Enlever la gestion du nombre de traitement retourné avec "set rowcount"
	2015-12-24	Donald Huppé			Temporaire : En décembre, ne pas filtrer les traitements
	2016-01-13	Pierre-Luc Simard	Ne pas filtrer selon la date si le EffectDays est à zéro (Donc pas un représentant)


	exec SP_CrqSearchRepTreatment
*/
/* Limite le nombre d'enregistrement retourné */
-- SET ROWCOUNT @TreatmentCount 

/* Retourne les traitements de commissions et leur date */
SELECT RepTreatmentID, RepTreatmentDate 
FROM Un_RepTreatment 
WHERE RepTreatmentDate <= GETDATE() - (@EffectDays - 1 ) -- la date de traitement doit être plus petite ou égale à la date du jour moins les jours d'attente
	OR @EffectDays = 0 --MONTH(RepTreatmentDate) = 12
ORDER BY RepTreatmentID DESC

/* Réinitialise l'option limitant le nombre d'enregistrement retourné */
SET ROWCOUNT 0

/* FIN DES TRAITEMENTS */
RETURN 0


