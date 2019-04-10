CREATE VIEW [dbo].[VStatistiquesAdmissibiliteTremplin] AS
SELECT DateConsentement = COALESCE(consentement.dtConsentement_Tremplin, GETDATE()),
	   Consentement = SUM(CASE WHEN consentement.bConsentement_Tremplin = 1 THEN 1 ELSE 0 END), 
       Refus = SUM(CASE WHEN consentement.bConsentement_Tremplin = 0 THEN 1 ELSE 0 END), 
       NonRepondu = SUM(CASE WHEN consentement.bConsentement_Tremplin IS NULL THEN 1 ELSE 0 END)
FROM   (SELECT DISTINCT conventions.SubscriberID, 
                        conventions.bConsentement_Tremplin, 
						conventions.dtConsentement_Tremplin
        FROM   (SELECT Un_Subscriber.SubscriberID, 
                       Un_Subscriber.bConsentement_Tremplin, 
                       Un_Subscriber.dtConsentement_Tremplin,
                       Un_Convention.dtSignature, 
                       NbJourDepuisSignature = DATEDIFF(DAY, Un_Convention.dtSignature, CAST(DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1-DAY(GETDATE()), GETDATE()))) AS DATE)),
                       NbJourEcartDatePremiereOperationFinanciere = DATEDIFF(DAY, ConventionState.InForceDate, CAST(DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1-DAY(GETDATE()), GETDATE()))) AS DATE)) 
                FROM   Un_Convention 
                       INNER JOIN Un_Subscriber ON Un_Convention.SubscriberID = Un_Subscriber.SubscriberID 
                       INNER JOIN (SELECT ConventionActive.ConventionID, 
                                          firstUnitGroup.InForceDate 
                                   FROM   dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(GETDATE(), NULL) AS ConventionActive 
                                          INNER JOIN (SELECT ROW_NUMBER() OVER(PARTITION BY ConventionId ORDER BY UnitID ASC) AS RowNumber,
                                                             UnitID, 
                                                             ConventionID, 
                                                             InForceDate 
                                                      FROM   Un_Unit) AS firstUnitGroup 
                                                  ON ConventionActive.ConventionID = firstUnitGroup.ConventionID
                                   WHERE  ( ConventionActive.ConventionStateID = 'REE' ) OR ( ConventionActive.ConventionStateID = 'TRA' ) 
                                              AND RowNumber = 1) AS ConventionState 
                               ON Un_Convention.ConventionID = ConventionState.ConventionID) conventions
        WHERE  conventions.NbJourDepuisSignature >= 90 OR conventions.NbJourEcartDatePremiereOperationFinanciere >= 90) consentement 
GROUP BY consentement.dtConsentement_Tremplin