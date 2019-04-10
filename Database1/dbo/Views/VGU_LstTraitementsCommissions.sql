
CREATE VIEW [dbo].[VGU_LstTraitementsCommissions]
AS
SELECT     TOP 100 PERCENT RepTreatmentDate AS DateAu, RepTreatmentID,
                          (SELECT     TOP 1 Un_RepTreatment.RepTreatmentDate + 1
                            FROM          Un_RepTreatment
                            WHERE      Un_RepTreatment.RepTreatmentID < T.RepTreatmentID
                            GROUP BY Un_RepTreatment.RepTreatmentDate
                            ORDER BY Un_RepTreatment.RepTreatmentDate DESC) AS DateDu
FROM         dbo.Un_RepTreatment T
ORDER BY RepTreatmentDate DESC


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Vue retournant la liste des traitements de commission', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'VGU_LstTraitementsCommissions';

